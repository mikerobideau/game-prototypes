class_name PortfolioCards
extends RefCounted

const SECTORS := ["Retail", "Industry", "Finance", "Tech", "Services"]

const CAPS := ["penny", "small", "mid", "blue"]

const CARDS := [
	{"name": "Moonshot AI", "sector": "Tech", "cap": "penny", "rules": [
		{"nums": [1], "name": "Meltdown", "fx": {"bankrupt": 1}},
		{"color": "blue", "name": "Hype", "fx": {"value": 0.4}},
		{"nums": [6], "name": "Unicorn", "fx": {"value": 0.8}},
	]},
	{"name": "ClickStorm Media", "sector": "Tech", "cap": "penny", "rules": [
		{"nums": [1, 2], "name": "Backlash", "fx": {"value": -0.3}},
		{"nums": [5, 6], "name": "Viral", "fx": {"value": 0.5}},
	]},
	{"name": "Bytewise Apps", "sector": "Tech", "cap": "small", "rules": [
		{"nums": [1], "name": "Bugs", "fx": {"value": -0.2}},
		{"color": "blue", "name": "Featured", "fx": {"value": 0.25}},
		{"nums": [4, 5, 6], "name": "Downloads", "fx": {"value": 0.15}},
	]},
	{"name": "Silicon Ridge", "sector": "Tech", "cap": "mid", "rules": [
		{"color": "red", "name": "Shortage", "fx": {"value": -0.2}},
		{"nums": [2, 4, 6], "name": "Contracts", "fx": {"value": 0.1}},
		{"nums": [6], "name": "Design win", "fx": {"value": 0.35}},
	]},
	{"name": "Streamline TV", "sector": "Tech", "cap": "mid", "rules": [
		{"nums": [1, 2], "name": "Churn", "fx": {"value": -0.15}},
		{"color": "purple", "name": "Hit series", "fx": {"value": 0.3}},
		{"nums": [5, 6], "name": "Subscriptions", "fx": {"cash": 4}},
	]},
	{"name": "Omnisoft", "sector": "Tech", "cap": "blue", "rules": [
		{"nums": [1], "name": "Breach", "fx": {"value": -0.15}},
		{"color": "blue", "name": "Platform", "fx": {"value": 0.2}},
		{"nums": [3, 4, 5, 6], "name": "Licences", "fx": {"cash": 3}},
	]},
	{"name": "Fad Factory", "sector": "Retail", "cap": "penny", "rules": [
		{"nums": [1], "name": "Fire", "fx": {"bankrupt": 1}},
		{"color": "orange", "name": "Trend", "fx": {"value": 0.4}},
		{"nums": [6], "name": "Bestseller", "fx": {"value": 0.7}},
	]},
	{"name": "Corner Kombucha", "sector": "Retail", "cap": "penny", "rules": [
		{"nums": [1, 2], "name": "Spoilage", "fx": {"value": -0.3}},
		{"color": "green", "name": "Health craze", "fx": {"value": 0.4}},
		{"nums": [5, 6], "name": "Buzz", "fx": {"value": 0.25}},
	]},
	{"name": "Velvet Lane", "sector": "Retail", "cap": "small", "rules": [
		{"nums": [1], "name": "Slump", "fx": {"value": -0.2}},
		{"color": "orange", "name": "Sellout", "fx": {"value": 0.3}},
		{"nums": [4, 5], "name": "Loyalty", "fx": {"cash": 3}},
	]},
	{"name": "Hearth Bakery", "sector": "Retail", "cap": "small", "rules": [
		{"color": "purple", "name": "Flour costs", "fx": {"value": -0.15}},
		{"nums": [2, 4, 6], "name": "Regulars", "fx": {"cash": 2}},
		{"nums": [6], "name": "Famous", "fx": {"value": 0.25}},
	]},
	{"name": "Roadster Motors", "sector": "Retail", "cap": "mid", "rules": [
		{"nums": [1, 2], "name": "Recall", "fx": {"value": -0.25}},
		{"color": "red", "name": "Supply deal", "fx": {"value": 0.2}},
		{"nums": [6], "name": "Launch", "fx": {"value": 0.4}},
	]},
	{"name": "Grand Bazaar", "sector": "Retail", "cap": "blue", "rules": [
		{"nums": [1], "name": "Theft", "fx": {"value": -0.1}},
		{"color": "orange", "name": "Black Friday", "fx": {"value": 0.25}},
		{"nums": [3, 4, 5, 6], "name": "Steady", "fx": {"cash": 3}},
	]},
	{"name": "Wildcat Drilling", "sector": "Industry", "cap": "penny", "rules": [
		{"nums": [1], "name": "Dry hole", "fx": {"bankrupt": 1}},
		{"color": "red", "name": "Strike", "fx": {"value": 0.45}},
		{"nums": [6], "name": "Gusher", "fx": {"value": 0.9}},
	]},
	{"name": "Rust Belt Rail", "sector": "Industry", "cap": "penny", "rules": [
		{"nums": [1, 2], "name": "Derailment", "fx": {"value": -0.35}},
		{"nums": [5, 6], "name": "Contract", "fx": {"value": 0.4}},
	]},
	{"name": "Precision Parts", "sector": "Industry", "cap": "small", "rules": [
		{"nums": [1], "name": "Breakdown", "fx": {"value": -0.2}},
		{"color": "red", "name": "Orders", "fx": {"value": 0.25}},
		{"nums": [3, 4], "name": "Steady", "fx": {"cash": 2}},
	]},
	{"name": "Ironworks Steel", "sector": "Industry", "cap": "mid", "rules": [
		{"nums": [1, 2], "name": "Imports", "fx": {"value": -0.2}},
		{"color": "red", "name": "Tariff win", "fx": {"value": 0.3}},
		{"nums": [5, 6], "name": "Contracts", "fx": {"value": 0.15}},
	]},
	{"name": "SkyLift Airlines", "sector": "Industry", "cap": "mid", "rules": [
		{"nums": [1], "name": "Grounded", "fx": {"value": -0.3}},
		{"color": "purple", "name": "Holiday rush", "fx": {"value": 0.3}},
		{"nums": [4, 5, 6], "name": "Bookings", "fx": {"cash": 3}},
	]},
	{"name": "Titan Machinery", "sector": "Industry", "cap": "blue", "rules": [
		{"color": "green", "name": "Credit squeeze", "fx": {"value": -0.1}},
		{"color": "red", "name": "Mega contract", "fx": {"value": 0.25}},
		{"nums": [2, 3, 4, 5], "name": "Backlog", "fx": {"cash": 3}},
	]},
	{"name": "QuickCash Loans", "sector": "Finance", "cap": "penny", "rules": [
		{"nums": [1], "name": "Raid", "fx": {"bankrupt": 1}},
		{"color": "green", "name": "Fees", "fx": {"value": 0.4}},
		{"nums": [6], "name": "Takeover", "fx": {"value": 0.8}},
	]},
	{"name": "Flip House", "sector": "Finance", "cap": "penny", "rules": [
		{"nums": [1, 2], "name": "Stale", "fx": {"value": -0.3}},
		{"color": "orange", "name": "Bidding war", "fx": {"value": 0.45}},
		{"nums": [6], "name": "Flip", "fx": {"cash": 6}},
	]},
	{"name": "Harbor Credit", "sector": "Finance", "cap": "small", "rules": [
		{"nums": [1], "name": "Bad loan", "fx": {"value": -0.2}},
		{"color": "green", "name": "Deposits", "fx": {"value": 0.25}},
		{"nums": [2, 4, 6], "name": "Interest", "fx": {"cash": 2}},
	]},
	{"name": "Keystone Insurance", "sector": "Finance", "cap": "mid", "rules": [
		{"color": "red", "name": "Big claim", "fx": {"value": -0.25}},
		{"color": "green", "name": "Premiums", "fx": {"value": 0.2}},
		{"nums": [3, 4, 5], "name": "Steady", "fx": {"cash": 3}},
	]},
	{"name": "Downtown Lofts", "sector": "Finance", "cap": "mid", "rules": [
		{"nums": [1, 2], "name": "Vacancy", "fx": {"value": -0.2}},
		{"color": "yellow", "name": "Boom", "fx": {"value": 0.25}},
		{"nums": [6], "name": "Development", "fx": {"value": 0.4}},
	]},
	{"name": "Monolith Bank", "sector": "Finance", "cap": "blue", "rules": [
		{"nums": [1], "name": "Default", "fx": {"value": -0.15}},
		{"color": "green", "name": "Merger", "fx": {"value": 0.25}},
		{"nums": [3, 4, 5, 6], "name": "Interest", "fx": {"cash": 4}},
	]},
	{"name": "Miracle Labs", "sector": "Services", "cap": "penny", "rules": [
		{"nums": [1], "name": "Trial fails", "fx": {"bankrupt": 1}},
		{"color": "purple", "name": "Promising", "fx": {"value": 0.4}},
		{"nums": [6], "name": "Approval", "fx": {"value": 1.0}},
	]},
	{"name": "Spark Co-op", "sector": "Services", "cap": "penny", "rules": [
		{"nums": [1, 2], "name": "Blackout", "fx": {"value": -0.3}},
		{"color": "yellow", "name": "Heat wave", "fx": {"value": 0.45}},
		{"nums": [5, 6], "name": "Fees", "fx": {"cash": 4}},
	]},
	{"name": "Clearview Clinics", "sector": "Services", "cap": "small", "rules": [
		{"nums": [1], "name": "Lawsuit", "fx": {"value": -0.25}},
		{"color": "purple", "name": "New wing", "fx": {"value": 0.25}},
		{"nums": [3, 4, 5], "name": "Patients", "fx": {"cash": 2}},
	]},
	{"name": "Vital Devices", "sector": "Services", "cap": "mid", "rules": [
		{"nums": [1, 2], "name": "Recall", "fx": {"value": -0.2}},
		{"color": "blue", "name": "Smart device", "fx": {"value": 0.3}},
		{"nums": [6], "name": "Contract", "fx": {"value": 0.3}},
	]},
	{"name": "Northwind Power", "sector": "Services", "cap": "mid", "rules": [
		{"color": "red", "name": "Outage", "fx": {"value": -0.2}},
		{"color": "purple", "name": "Grid deal", "fx": {"value": 0.25}},
		{"nums": [2, 3, 4, 5], "name": "Demand", "fx": {"cash": 3}},
	]},
	{"name": "Meridian Pharma", "sector": "Services", "cap": "blue", "rules": [
		{"nums": [1], "name": "Generics", "fx": {"value": -0.15}},
		{"color": "purple", "name": "Blockbuster", "fx": {"value": 0.25}},
		{"nums": [4, 5, 6], "name": "Dividend", "fx": {"cash": 4}},
	]},
]
