from flask import Flask, render_template, request, redirect, url_for, flash
from pymongo import MongoClient
from bson.objectid import ObjectId
import os
import json
from dotenv import load_dotenv
import logging
from logging.handlers import RotatingFileHandler
from urllib.parse import quote_plus

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", os.urandom(24))

# Configure logging
if not app.debug:
    if not os.path.exists("logs"):
        os.mkdir("logs")
    file_handler = RotatingFileHandler("logs/app.log", maxBytes=10240, backupCount=10)
    file_handler.setFormatter(
        logging.Formatter(
            "%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]"
        )
    )
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)
    app.logger.info("DnD Monster Data startup")


# MongoDB connection with retry logic
def get_mongo_client():
    mongo_user = os.getenv("ONGO_INITDB_ROOT_USERNAME", "admin")
    mongo_pass = os.getenv("MONGO_INITDB_ROOT_PASSWORD", "changeme")
    mongo_db = os.getenv("MONGO_DB_NAME", "dnd_monster_data")
    mongo_host = os.getenv("MONGO_HOST", "mongo")
    mongo_port = os.getenv("MONGO_PORT", "27017")

    # URL encode username and password to handle special characters
    encoded_user = quote_plus(mongo_user)
    encoded_pass = quote_plus(mongo_pass)

    mongo_uri = f"mongodb://{encoded_user}:{encoded_pass}@{mongo_host}:{mongo_port}/"
    try:
        client = MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
        # Test the connection
        client.admin.command("ping")
        return client
    except Exception as e:
        app.logger.error(f"Failed to connect to MongoDB: {str(e)}")
        raise


# Initialize MongoDB connection and collections
client = None
db = None
creatures = None

try:
    client = get_mongo_client()
    db = client[os.getenv("MONGO_DB", "dnd_monster_data")]
    creatures = db["creatures"]
    app.logger.info("MongoDB connection established successfully")
except Exception as e:
    app.logger.error(f"Initial MongoDB connection failed: {str(e)}")
    # Initialize with None to prevent NameError
    client = None
    db = None
    creatures = None


@app.route("/")
def index():
    if creatures is None:
        flash("Database connection error. Please check the logs.", "error")
        return render_template("index.html", creatures=[])

    try:
        all_creatures = list(creatures.find())
        return render_template("index.html", creatures=all_creatures)
    except Exception as e:
        app.logger.error(f"Error fetching creatures: {str(e)}")
        flash("Error loading creatures from database.", "error")
        return render_template("index.html", creatures=[])


def get_proficiency_bonus(cr):
    if cr <= 4:
        return 2
    elif cr <= 8:
        return 3
    elif cr <= 12:
        return 4
    elif cr <= 16:
        return 5
    elif cr <= 20:
        return 6
    elif cr <= 24:
        return 7
    elif cr <= 28:
        return 8
    else:
        return 9


def get_xp(cr):
    xp_table = {
        0: 0,
        0.125: 25,
        0.25: 50,
        0.5: 100,
        1: 200,
        2: 450,
        3: 700,
        4: 1100,
        5: 1800,
        6: 2300,
        7: 2900,
        8: 3900,
        9: 5000,
        10: 5900,
        11: 7200,
        12: 8400,
        13: 10000,
        14: 11500,
        15: 13000,
        16: 15000,
        17: 18000,
        18: 20000,
        19: 22000,
        20: 25000,
        21: 33000,
        22: 41000,
        23: 50000,
        24: 62000,
        25: 75000,
        26: 90000,
        27: 105000,
        28: 120000,
        29: 135000,
        30: 155000,
    }
    return xp_table.get(float(cr), 0)


@app.route("/add", methods=["GET", "POST"])
def add_creature():
    if request.method == "POST":
        cr = float(request.form["challenge_rating"])
        challenge_rating = cr if 0 < cr < 1 else int(cr)
        creature_data = {
            "name": request.form["name"],
            "index": request.form["name"].lower().replace(" ", "_"),
            "desc": request.form["desc"],
            "salvage": request.form["salvage"],
            "lore": [
                entry for entry in request.form.getlist("lore[]") if entry.strip()
            ],
            "size": request.form["size"],
            "type": request.form["type"]
            + (f" ({request.form['type_tag']})" if request.form["type_tag"] else ""),
            "alignment": request.form["alignment"],
            "armor_class": (
                int(request.form["armor_class"])
                if request.form["armor_class"]
                else None
            ),
            "hit_points": (
                int(request.form["hit_points"]) if request.form["hit_points"] else 0
            ),
            "hit_dice": request.form["hit_dice"],
            "speed": {
                k: v
                for k, v in {
                    "walk": request.form["speed_walk"],
                    "fly": request.form["speed_fly"],
                    "swim": request.form["speed_swim"],
                    "climb": request.form["speed_climb"],
                    "burrow": request.form["speed_burrow"],
                }.items()
                if v
            },
            "strength": (
                int(request.form["strength"]) if request.form["strength"] else 0
            ),
            "dexterity": (
                int(request.form["dexterity"]) if request.form["dexterity"] else 0
            ),
            "constitution": (
                int(request.form["constitution"]) if request.form["constitution"] else 0
            ),
            "intelligence": (
                int(request.form["intelligence"]) if request.form["intelligence"] else 0
            ),
            "wisdom": int(request.form["wisdom"]) if request.form["wisdom"] else 0,
            "charisma": (
                int(request.form["charisma"]) if request.form["charisma"] else 0
            ),
            "senses": {
                "passive_perception": int(request.form["passive_perception"]),
                **{
                    sense_type: f"{range_} ft."
                    for sense_type, range_ in zip(
                        request.form.getlist("sense_type[]"),
                        request.form.getlist("sense_range[]"),
                    )
                    if sense_type and range_
                },
            },
            "languages": request.form["languages"],
            "challenge_rating": challenge_rating,
            "proficiency_bonus": get_proficiency_bonus(challenge_rating),
            "xp": get_xp(challenge_rating),
            "proficiencies": [
                {
                    "value": int(value),
                    "proficiency": {
                        "index": name,
                        "name": name.replace("-", " ")
                        .title()
                        .replace("Str", "STR")
                        .replace("Dex", "DEX")
                        .replace("Con", "CON")
                        .replace("Int", "INT")
                        .replace("Wis", "WIS")
                        .replace("Cha", "CHA"),
                    },
                }
                for type_, name, value in zip(
                    request.form.getlist("proficiency_type[]"),
                    request.form.getlist("proficiency_name[]"),
                    request.form.getlist("proficiency_value[]"),
                )
                if type_ and name and value
            ],
            "damage_vulnerabilities": (
                [v for v in request.form.getlist("vulnerability[]") if v]
                + (
                    ["bludgeoning", "piercing", "slashing from nonmagical weapons"]
                    if request.form.get("vulnerability-nonmagical")
                    else []
                )
            ),
            "damage_resistances": (
                [r for r in request.form.getlist("resistance[]") if r]
                + (
                    ["bludgeoning", "piercing", "slashing from nonmagical weapons"]
                    if request.form.get("resistance-nonmagical")
                    else []
                )
            ),
            "damage_immunities": (
                [i for i in request.form.getlist("immunity[]") if i]
                + (
                    ["bludgeoning", "piercing", "slashing from nonmagical weapons"]
                    if request.form.get("immunity-nonmagical")
                    else []
                )
            ),
            "condition_immunities": [
                c for c in request.form.getlist("condition_immunity[]") if c
            ],
            "special_abilities": [
                {"name": name, "desc": desc}
                for name, desc in zip(
                    request.form.getlist("ability_name[]"),
                    request.form.getlist("ability_desc[]"),
                )
                if name and desc
            ],
            "actions": [
                {
                    "name": name,
                    "desc": desc,
                    "attack_bonus": int(attack_bonus) if attack_bonus else None,
                    "damage": [
                        {
                            "damage_type": {
                                "index": damage_type.lower(),
                                "name": damage_type,
                            },
                            "damage_dice": damage_dice,
                        }
                        for damage_type, damage_dice in zip(
                            request.form.getlist("action_damage_type[]"),
                            request.form.getlist("action_damage_dice[]"),
                        )
                        if damage_type and damage_dice
                    ],
                    "actions": [],  # Placeholder for nested actions if needed
                }
                for name, desc, attack_bonus in zip(
                    request.form.getlist("action_name[]"),
                    request.form.getlist("action_desc[]"),
                    request.form.getlist("action_attack_bonus[]"),
                )
                if name and desc
            ],
            "reactions": [
                {"name": name, "desc": desc}
                for name, desc in zip(
                    request.form.getlist("reaction_name[]"),
                    request.form.getlist("reaction_desc[]"),
                )
                if name and desc
            ],
            "legendary_actions": [
                {
                    "name": name,
                    "desc": desc,
                    "actions": [],  # Placeholder for nested actions if needed
                }
                for name, desc in zip(
                    request.form.getlist("legendary_action_name[]"),
                    request.form.getlist("legendary_action_desc[]"),
                )
                if name and desc
            ],
        }

        # Insert into MongoDB
        if creatures is None:
            flash("Database connection error. Cannot add creature.", "error")
            return redirect(url_for("index"))

        try:
            creatures.insert_one(creature_data)
            flash("Creature added successfully!", "success")
            return redirect(url_for("index"))
        except Exception as e:
            app.logger.error(f"Error inserting creature: {str(e)}")
            flash("Error adding creature to database.", "error")
            return redirect(url_for("index"))

    return render_template("add.html")


@app.route("/search")
def search():
    if creatures is None:
        flash("Database connection error. Please check the logs.", "error")
        return render_template(
            "search.html",
            creatures=[],
            query="",
            selected_type="",
            min_cr="",
            max_cr="",
            creature_types=[],
        )

    query = request.args.get("q", "")
    creature_type = request.args.get("type", "")
    min_cr = request.args.get("min_cr", "")
    max_cr = request.args.get("max_cr", "")

    # Build the search query
    search_query = {}

    # Text search across name and description
    if query:
        search_query["$or"] = [
            {"name": {"$regex": query, "$options": "i"}},
            {"desc": {"$regex": query, "$options": "i"}},
        ]

    # Filter by creature type
    if creature_type:
        search_query["type"] = {"$regex": creature_type, "$options": "i"}

    # Filter by challenge rating range
    if min_cr or max_cr:
        cr_query = {}
        if min_cr:
            cr_query["$gte"] = float(min_cr)
        if max_cr:
            cr_query["$lte"] = float(max_cr)
        search_query["challenge_rating"] = cr_query

    try:
        # Get all creature types for the filter dropdown
        all_types = creatures.distinct("type")

        # Execute search
        if search_query:
            results = list(
                creatures.find(search_query).sort(
                    [
                        ("type", 1),  # Sort by type first
                        ("challenge_rating", 1),  # Then by challenge rating
                    ]
                )
            )
        else:
            results = []

        return render_template(
            "search.html",
            creatures=results,
            query=query,
            selected_type=creature_type,
            min_cr=min_cr,
            max_cr=max_cr,
            creature_types=all_types,
        )
    except Exception as e:
        app.logger.error(f"Error searching creatures: {str(e)}")
        flash("Error searching database.", "error")
        return render_template(
            "search.html",
            creatures=[],
            query=query,
            selected_type=creature_type,
            min_cr=min_cr,
            max_cr=max_cr,
            creature_types=[],
        )


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
