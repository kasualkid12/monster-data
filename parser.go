package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// CreatureCollection represents the entire JSON structure with the creature name as the key
type CreatureCollection map[string]Creature

// Creature represents the details of a single creature
type Creature struct {
	Index                 string            `json:"index"`
	Name                  string            `json:"name"`
	Desc                  string            `json:"desc"`
	Salvage               string            `json:"salvage"`
	Lore                  []string          `json:"lore"`
	Size                  string            `json:"size"`
	Type                  string            `json:"type"`
	Alignment             string            `json:"alignment"`
	ArmorClass            []ArmorClass      `json:"armor_class"`
	HitPoints             int               `json:"hit_points"`
	HitDice               string            `json:"hit_dice"`
	HitPointsRoll         string            `json:"hit_points_roll"`
	Speed                 Speed             `json:"speed"`
	Strength              int               `json:"strength"`
	Dexterity             int               `json:"dexterity"`
	Constitution          int               `json:"constitution"`
	Intelligence          int               `json:"intelligence"`
	Wisdom                int               `json:"wisdom"`
	Charisma              int               `json:"charisma"`
	Proficiencies         []Proficiency     `json:"proficiencies"`
	DamageVulnerabilities []string          `json:"damage_vulnerabilities"`
	DamageResistances     []string          `json:"damage_resistances"`
	DamageImmunities      []string          `json:"damage_immunities"`
	ConditionImmunities   []string          `json:"condition_immunities"`
	Senses                Senses            `json:"senses"`
	Languages             string            `json:"languages"`
	ChallengeRating       float64           `json:"challenge_rating"`
	ProficiencyBonus      int               `json:"proficiency_bonus"`
	XP                    int               `json:"xp"`
	SpecialAbilities      []SpecialAbility  `json:"special_abilities"`
	Actions               []Action          `json:"actions"`
	Reactions             []Action          `json:"reactions"`
	LegendaryActions      []LegendaryAction `json:"legendary_actions"`
}

// ArmorClass represents an individual armor class entry
type ArmorClass struct {
	Type  string `json:"type"`
	Value int    `json:"value"`
}

// Speed represents the creature's movement speeds
type Speed struct {
	Walk  string `json:"walk,omitempty"`  // Optional
	Climb string `json:"climb,omitempty"` // Optional
	Fly   string `json:"fly,omitempty"`   // Optional
	Swim  string `json:"swim,omitempty"`  // Optional
}

// Proficiency represents a skill or saving throw proficiency
type Proficiency struct {
	Value       int        `json:"value"`
	Proficiency SkillEntry `json:"proficiency"`
}

// SkillEntry represents the index and name of a proficiency
type SkillEntry struct {
	Index string `json:"index"`
	Name  string `json:"name"`
}

// Senses represents the creature's senses
type Senses struct {
	Blindsight        string `json:"blindsight,omitempty"`  // Optional
	Darkvision        string `json:"darkvision,omitempty"`  // Optional
	Tremorsense       string `json:"tremorsense,omitempty"` // Optional
	Truesight         string `json:"truesight,omitempty"`   // Optional
	PassivePerception int    `json:"passive_perception"`    // Mandatory
}

// SpecialAbility represents a single special ability
type SpecialAbility struct {
	Name string `json:"name"`
	Desc string `json:"desc"`
}

// Action represents an action or reaction
type Action struct {
	Name        string   `json:"name"`
	Desc        string   `json:"desc"`
	AttackBonus int      `json:"attack_bonus,omitempty"` // Optional
	Damage      []Damage `json:"damage,omitempty"`       // Optional
	SubActions  []Action `json:"actions,omitempty"`      // Nested actions (optional)
}

// Damage represents the damage information for an action
type Damage struct {
	DamageType DamageType `json:"damage_type"`
	DamageDice string     `json:"damage_dice"`
}

// DamageType represents the type of damage
type DamageType struct {
	Index string `json:"index"`
	Name  string `json:"name"`
}

// LegendaryAction represents a legendary action
type LegendaryAction struct {
	Name       string   `json:"name"`
	Desc       string   `json:"desc"`
	SubActions []Action `json:"actions,omitempty"` // Nested actions (optional)
}

// Main function to orchestrate parsing and JSON creation
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <input_file>")
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := "creature.json"

	// Validate file extension
	if err := validateFileExtension(inputFile); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	// Read the input file
	content, err := os.ReadFile(inputFile)
	if err != nil {
		fmt.Printf("Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Parse the creature from the text
	creature, err := parseCreature(string(content))
	if err != nil {
		fmt.Printf("Error parsing creature: %v\n", err)
		os.Exit(1)
	}

	// Wrap the creature in a CreatureCollection
	creatureCollection := CreatureCollection{
		creature.Name: creature,
	}

	// Serialize to JSON
	jsonData, err := json.MarshalIndent(creatureCollection, "", "  ")
	if err != nil {
		fmt.Printf("Error creating JSON: %v\n", err)
		os.Exit(1)
	}

	// Write JSON to file
	err = os.WriteFile(outputFile, jsonData, 0644)
	if err != nil {
		fmt.Printf("Error writing JSON to file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Creature JSON saved to %s\n", outputFile)
}

// validateFileExtension ensures the input file has a .txt extension
func validateFileExtension(filePath string) error {
	if filepath.Ext(filePath) != ".txt" {
		return errors.New("invalid file type: only .txt files are allowed")
	}
	return nil
}

// parseCreature parses the creature data from a text input and returns a Creature struct
func parseCreature(data string) (Creature, error) {
	data = strings.TrimSpace(data)

	if data == "" {
		return Creature{}, errors.New("input data is empty")
	}

	lines := strings.Split(data, "\n")
	if len(lines) < 1 || strings.TrimSpace(lines[0]) == "" {
		return Creature{}, errors.New("creature name is missing in the input data")
	}

	name := strings.TrimSpace(lines[0])
	creature := Creature{
		Name:  name,
		Index: strings.ToLower(strings.ReplaceAll(name, " ", "-")),
	}

	// Parse description
	desc, nextIndex := parseDescription(lines, creature.Name)
	creature.Desc = desc

	// Parse salvage (optional)
	salvage, nextIndex := parseSalvage(lines, creature.Name, nextIndex)
	creature.Salvage = salvage

	return creature, nil
}

// parseDescription extracts the description from the input data
func parseDescription(lines []string, creatureName string) (string, int) {
	description := []string{}
	creatureNameLower := strings.ToLower(creatureName)
	startIndex := 1 // Start after the name (first line)

	for i := startIndex; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		lineLower := strings.ToLower(line)

		// Check if the line is a stopping point
		if lineLower == "salvage" || lineLower == "lore" || lineLower == creatureNameLower {
			return strings.TrimSpace(strings.Join(description, " ")), i
		}

		// Add the line to the description
		description = append(description, line)
	}

	return strings.TrimSpace(strings.Join(description, " ")), len(lines)
}

// parseSalvage extracts the salvage section from the input data
func parseSalvage(lines []string, creatureName string, startIndex int) (string, int) {
	salvage := []string{}
	creatureNameLower := strings.ToLower(creatureName)

	for i := startIndex; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		lineLower := strings.ToLower(line)

		// Skip the line with the word "salvage"
		if lineLower == "salvage" {
			continue
		}

		// Check if the line is a stopping point
		if lineLower == "lore" || lineLower == creatureNameLower {
			return strings.TrimSpace(strings.Join(salvage, " ")), i
		}

		// Add the line to the salvage section
		salvage = append(salvage, line)
	}

	// If no stopping point is found, return the collected salvage and the last index
	return strings.TrimSpace(strings.Join(salvage, " ")), len(lines)
}
