class_name MainStreetCards
extends RefCounted

## The 40 property cards: eight businesses in each of five sectors, two of each size.
##
## Each sector has a colour, matching one face colour on every die (yellow is wild):
##   Retail    orange   money and plans          Industry  red      bumps and extra dice
##   Finance   green    rent cuts and upgrades   Tech      blue     plans and big swings
##   Services  purple   guards and steady money
## Penny stocks swing wildly (a 1 usually destroys them); blue chips are steady.
##
## split: how the six die faces are grouped. Each card has one event per group, in this order:
##   "parity" Odd, Even     "split" 1-3, 4-6     "six" 1-5, 6     "one" 1, 2-6
##   "hml" 1-2, 3-4, 5-6    "ends" 1, 2-5, 6
##
## Each event has a title (flavour), a name (printed on the card), an optional level (the card must be at
## least this level for the event to work) and fx (what it does). An empty fx does nothing. fx keys:
##   cash       money at level 1; it grows with the card's level
##   upgrade    the card goes up (or down) this many levels
##   bump       the dice next door and across the street count this much higher (or lower)
##   guard      1 = the cards next door and across the street can't suffer bad effects today
##   draw       plans drawn into your hand
##   extra_die  extra dice in tomorrow's roll
##   rent       today's rent changed by this share; -0.3 = 30% off
##   destroy    1 = this property is destroyed

const SECTORS := ["Retail", "Industry", "Finance", "Tech", "Services"]

const SIZES := ["penny", "small", "mid", "blue"]

const CARDS := [
	# ------------------------------------------------ Retail: money and plans
	{"name": "Fad Factory", "sector": "Retail", "size": "penny", "split": "ends", "events": [
		{"title": "Warehouse fire", "name": "Fire", "fx": {"destroy": 1}},
		{"title": "Steady orders", "name": "Sales", "fx": {"cash": 2}},
		{"title": "Toy of the year", "name": "Bestseller", "level": 2, "fx": {"cash": 12}},
	]},
	{"name": "Corner Kombucha", "sector": "Retail", "size": "penny", "split": "hml", "events": [
		{"title": "Spoiled batch", "name": "Spoilage", "fx": {"cash": -4}},
		{"title": "Local buzz", "name": "Buzz", "fx": {"cash": 3}},
		{"title": "Picked up nationally", "name": "Expansion", "level": 2, "fx": {"cash": 4, "upgrade": 1}},
	]},
	{"name": "Velvet Lane", "sector": "Retail", "size": "small", "split": "hml", "events": [
		{"title": "Bad season", "name": "Slump", "fx": {"cash": -2}},
		{"title": "Loyalty cards", "name": "Loyalty", "fx": {"draw": 1}},
		{"title": "Sold out", "name": "Sellout", "level": 2, "fx": {"cash": 6}},
	]},
	{"name": "Hearth Bakery", "sector": "Retail", "size": "small", "split": "parity", "events": [
		{"title": "Flour costs rise", "name": "Costs", "fx": {"cash": -1}},
		{"title": "Bread for the block", "name": "Community", "fx": {"cash": 3}},
	]},
	{"name": "Roadster Motors", "sector": "Retail", "size": "mid", "split": "ends", "events": [
		{"title": "Safety recall", "name": "Recall", "fx": {"cash": -5}},
		{"title": "Test drives", "name": "Test drive", "fx": {"cash": 3}},
		{"title": "New model hit", "name": "Launch", "level": 2, "fx": {"cash": 8, "draw": 1}},
	]},
	{"name": "Sunny Soap", "sector": "Retail", "size": "mid", "split": "six", "events": [
		{"title": "Repeat buyers", "name": "Steady sales", "fx": {"cash": 3}},
		{"title": "New scent", "name": "Research", "level": 2, "fx": {"upgrade": 1}},
	]},
	{"name": "Grand Bazaar", "sector": "Retail", "size": "blue", "split": "six", "events": [
		{"title": "Store credit", "name": "Credit", "fx": {"cash": 3}},
		{"title": "Black Friday", "name": "Black Friday", "level": 2, "fx": {"cash": 10, "draw": 1}},
	]},
	{"name": "Pantry Goods", "sector": "Retail", "size": "blue", "split": "hml", "events": [
		{"title": "Supply snag", "name": "Snag", "fx": {}},
		{"title": "Keeps the shelves full", "name": "Supply", "fx": {"cash": 3}},
		{"title": "Bulk contract", "name": "Bulk deal", "level": 3, "fx": {"cash": 6}},
	]},
	# ------------------------------------------------ Industry: bumps and extra dice
	{"name": "Wildcat Drilling", "sector": "Industry", "size": "penny", "split": "ends", "events": [
		{"title": "Dry hole", "name": "Bankrupt", "fx": {"destroy": 1}},
		{"title": "Survey crew", "name": "Survey", "fx": {"cash": 2}},
		{"title": "Gusher!", "name": "Gusher", "level": 2, "fx": {"cash": 14}},
	]},
	{"name": "Rust Belt Rail", "sector": "Industry", "size": "penny", "split": "hml", "events": [
		{"title": "Derailment", "name": "Derailment", "fx": {"cash": -5, "rent": 0.2}},
		{"title": "On schedule", "name": "Logistics", "fx": {"bump": 1}},
		{"title": "Federal contract", "name": "Contract", "level": 2, "fx": {"cash": 8}},
	]},
	{"name": "Precision Parts", "sector": "Industry", "size": "small", "split": "parity", "events": [
		{"title": "Machine breaks down", "name": "Breakdown", "fx": {"cash": -1}},
		{"title": "Parts for the block", "name": "Vendor", "fx": {"cash": 2, "bump": 1}},
	]},
	{"name": "Sunbeam Solar", "sector": "Industry", "size": "small", "split": "hml", "events": [
		{"title": "Cloudy week", "name": "Clouds", "fx": {"cash": -2}},
		{"title": "Grid credits", "name": "Credits", "fx": {"rent": -0.2}},
		{"title": "Sunny streak", "name": "Boom", "level": 2, "fx": {"cash": 4, "extra_die": 1}},
	]},
	{"name": "Ironworks Steel", "sector": "Industry", "size": "mid", "split": "hml", "events": [
		{"title": "Cheap imports", "name": "Imports", "fx": {"cash": -3}},
		{"title": "Supply contracts", "name": "Vendor", "fx": {"cash": 3}},
		{"title": "Tariff win", "name": "Tariffs", "level": 2, "fx": {"cash": 7}},
	]},
	{"name": "SkyLift Airlines", "sector": "Industry", "size": "mid", "split": "ends", "events": [
		{"title": "Fleet grounded", "name": "Grounded", "fx": {"cash": -6}},
		{"title": "Full flights", "name": "Bookings", "fx": {"cash": 3}},
		{"title": "Holiday rush", "name": "Rush", "level": 2, "fx": {"cash": 5, "extra_die": 1}},
	]},
	{"name": "Titan Machinery", "sector": "Industry", "size": "blue", "split": "six", "events": [
		{"title": "Order backlog", "name": "Backlog", "fx": {"cash": 3}},
		{"title": "Mega contract", "name": "Contract", "level": 2, "fx": {"cash": 6, "bump": 2}},
	]},
	{"name": "Atlas Petroleum", "sector": "Industry", "size": "blue", "split": "ends", "events": [
		{"title": "Oil spill", "name": "Spill", "fx": {"cash": -6}},
		{"title": "Oil dividend", "name": "Dividend", "fx": {"cash": 3}},
		{"title": "Supply cut", "name": "Embargo", "level": 3, "fx": {"cash": 9}},
	]},
	# ------------------------------------------------ Finance: rent cuts and upgrades
	{"name": "QuickCash Loans", "sector": "Finance", "size": "penny", "split": "ends", "events": [
		{"title": "Regulators raid", "name": "Raid", "fx": {"destroy": 1}},
		{"title": "Late fees", "name": "Fees", "fx": {"cash": 3}},
		{"title": "Hostile takeover", "name": "Takeover", "level": 2, "fx": {"cash": 12}},
	]},
	{"name": "Flip House Inc.", "sector": "Finance", "size": "penny", "split": "hml", "events": [
		{"title": "No buyers", "name": "Stale", "fx": {"cash": -4}},
		{"title": "Quick flip", "name": "Flip", "fx": {"cash": 4}},
		{"title": "Bidding war", "name": "Bidding", "level": 2, "fx": {"cash": 9}},
	]},
	{"name": "Harbor Credit Union", "sector": "Finance", "size": "small", "split": "parity", "events": [
		{"title": "Bad loan", "name": "Bad loan", "fx": {"cash": -1}},
		{"title": "Savings interest", "name": "Interest", "fx": {"cash": 3}},
	]},
	{"name": "Starter Homes", "sector": "Finance", "size": "small", "split": "six", "events": [
		{"title": "Rent checks", "name": "Rent", "fx": {"cash": 2}},
		{"title": "Refinanced", "name": "Refinance", "level": 2, "fx": {"rent": -0.3, "upgrade": 1}},
	]},
	{"name": "Keystone Insurance", "sector": "Finance", "size": "mid", "split": "hml", "events": [
		{"title": "Big claim", "name": "Claim", "fx": {"cash": -4}},
		{"title": "Premiums", "name": "Premiums", "fx": {"cash": 3, "guard": 1}},
		{"title": "Quiet year", "name": "Reserves", "level": 2, "fx": {"rent": -0.25}},
	]},
	{"name": "Downtown Lofts", "sector": "Finance", "size": "mid", "split": "ends", "events": [
		{"title": "Tenants move out", "name": "Vacancy", "fx": {"cash": -5}},
		{"title": "Long leases", "name": "Leases", "fx": {"cash": 4}},
		{"title": "New development", "name": "Develop", "level": 2, "fx": {"cash": 4, "upgrade": 1}},
	]},
	{"name": "Monolith Bank", "sector": "Finance", "size": "blue", "split": "six", "events": [
		{"title": "Interest income", "name": "Interest", "fx": {"cash": 3}},
		{"title": "Acquisition spree", "name": "Merger", "level": 2, "fx": {"cash": 6, "upgrade": 1}},
	]},
	{"name": "Pillar REIT", "sector": "Finance", "size": "blue", "split": "hml", "events": [
		{"title": "Market downturn", "name": "Downturn", "fx": {"cash": -2}},
		{"title": "Rental income", "name": "Income", "fx": {"cash": 3}},
		{"title": "Acquisition", "name": "Acquire", "level": 3, "fx": {"cash": 5, "rent": -0.2}},
	]},
	# ------------------------------------------------ Tech: plans and big swings
	{"name": "Moonshot AI", "sector": "Tech", "size": "penny", "split": "ends", "events": [
		{"title": "Servers melt", "name": "Meltdown", "fx": {"destroy": 1}},
		{"title": "Beta users", "name": "Beta", "fx": {"draw": 1}},
		{"title": "Unicorn", "name": "Unicorn", "level": 2, "fx": {"cash": 16}},
	]},
	{"name": "ClickStorm Media", "sector": "Tech", "size": "penny", "split": "hml", "events": [
		{"title": "Clickbait backlash", "name": "Backlash", "fx": {"cash": -5}},
		{"title": "Sponsored post", "name": "Sponsor", "fx": {"draw": 1}},
		{"title": "Viral sensation", "name": "Viral", "level": 2, "fx": {"cash": 9}},
	]},
	{"name": "Bytewise Apps", "sector": "Tech", "size": "small", "split": "hml", "events": [
		{"title": "Buggy update", "name": "Bugs", "fx": {"cash": -2}},
		{"title": "App store feature", "name": "Featured", "fx": {"cash": 3}},
		{"title": "Viral app", "name": "Viral", "level": 2, "fx": {"draw": 2}},
	]},
	{"name": "Hometown Radio", "sector": "Tech", "size": "small", "split": "parity", "events": [
		{"title": "Signal trouble", "name": "Static", "fx": {"cash": -1}},
		{"title": "Ad spots sold", "name": "Ads", "fx": {"cash": 3}},
	]},
	{"name": "Silicon Ridge Chips", "sector": "Tech", "size": "mid", "split": "split", "events": [
		{"title": "Chip shortage", "name": "Shortage", "fx": {"cash": -1}},
		{"title": "Design win", "name": "IP", "fx": {"cash": 5}},
	]},
	{"name": "Streamline TV", "sector": "Tech", "size": "mid", "split": "ends", "events": [
		{"title": "Subscribers cancel", "name": "Churn", "fx": {"cash": -5}},
		{"title": "Subscriptions", "name": "Subs", "fx": {"cash": 4}},
		{"title": "Hit series", "name": "Hit", "level": 2, "fx": {"cash": 8, "draw": 1}},
	]},
	{"name": "Omnisoft", "sector": "Tech", "size": "blue", "split": "six", "events": [
		{"title": "Subscriptions", "name": "Subs", "fx": {"cash": 3}},
		{"title": "Platform launch", "name": "Launch", "level": 2, "fx": {"draw": 1, "upgrade": 1}},
	]},
	{"name": "Bell Telecom", "sector": "Tech", "size": "blue", "split": "hml", "events": [
		{"title": "Network outage", "name": "Outage", "fx": {"cash": -2}},
		{"title": "Phone bills", "name": "Billing", "fx": {"cash": 3}},
		{"title": "Network rollout", "name": "Rollout", "level": 3, "fx": {"cash": 7}},
	]},
	# ------------------------------------------------ Services: guards and steady money
	{"name": "Miracle Labs", "sector": "Services", "size": "penny", "split": "ends", "events": [
		{"title": "Trial fails", "name": "Bankrupt", "fx": {"destroy": 1}},
		{"title": "Promising signs", "name": "Research", "fx": {"cash": 2}},
		{"title": "Approved!", "name": "Approval", "level": 2, "fx": {"cash": 16}},
	]},
	{"name": "Spark Co-op", "sector": "Services", "size": "penny", "split": "hml", "events": [
		{"title": "Blackout", "name": "Blackout", "fx": {"cash": -5}},
		{"title": "Line fees", "name": "Fees", "fx": {"cash": 3}},
		{"title": "State subsidy", "name": "Subsidy", "level": 2, "fx": {"cash": 6, "rent": -0.3}},
	]},
	{"name": "Clearview Clinics", "sector": "Services", "size": "small", "split": "hml", "events": [
		{"title": "Malpractice suit", "name": "Lawsuit", "fx": {"cash": -2}},
		{"title": "Full waiting room", "name": "Patients", "fx": {"cash": 3}},
		{"title": "New wing opens", "name": "Growth", "level": 2, "fx": {"upgrade": 1}},
	]},
	{"name": "Clearwater Utility", "sector": "Services", "size": "small", "split": "parity", "events": [
		{"title": "Pipe burst", "name": "Burst", "fx": {"cash": -1, "rent": 0.1}},
		{"title": "Water bills", "name": "Billing", "fx": {"cash": 2, "guard": 1}},
	]},
	{"name": "Vital Devices", "sector": "Services", "size": "mid", "split": "split", "events": [
		{"title": "Device recall", "name": "Recall", "fx": {"cash": -2}},
		{"title": "Hospital contract", "name": "Contract", "fx": {"cash": 5}},
	]},
	{"name": "Northwind Power", "sector": "Services", "size": "mid", "split": "ends", "events": [
		{"title": "Rate freeze", "name": "Freeze", "fx": {}},
		{"title": "Steady demand", "name": "Demand", "fx": {"cash": 3}},
		{"title": "Powers the street", "name": "Grid", "level": 2, "fx": {"cash": 5, "guard": 1}},
	]},
	{"name": "Meridian Pharma", "sector": "Services", "size": "blue", "split": "ends", "events": [
		{"title": "Patent expires", "name": "Generics", "fx": {"cash": -3}},
		{"title": "Pharma dividend", "name": "Dividend", "fx": {"cash": 3}},
		{"title": "Blockbuster drug", "name": "IP", "level": 3, "fx": {"cash": 8, "upgrade": 1}},
	]},
	{"name": "Unity Electric", "sector": "Services", "size": "blue", "split": "one", "events": [
		{"title": "Regulator fine", "name": "Sanctions", "fx": {"cash": -3}},
		{"title": "Keeps the lights on", "name": "Service", "fx": {"cash": 3, "guard": 1}},
	]},
]
