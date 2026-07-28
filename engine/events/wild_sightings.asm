; Each profile contains supported encounter-method flags and a pointer to a
; weighted species table. Species tables are intentionally empty until their
; contents are balanced separately from the engine framework.
WildSightingProfiles:
	sighting_profile 0, NoWildSightings
	sighting_profile SIGHTING_METHOD_LAND, EarlyGrasslandSightings
	sighting_profile SIGHTING_METHOD_LAND, ForestSightings
	sighting_profile SIGHTING_METHOD_LAND, RockyRouteSightings
	sighting_profile SIGHTING_METHOD_LAND, MountainCaveSightings
	sighting_profile SIGHTING_METHOD_LAND, UrbanOutskirtsSightings
	sighting_profile SIGHTING_METHOD_LAND, WetlandSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, CoastalSightings
	sighting_profile SIGHTING_METHOD_WATER, OpenOceanSightings
	sighting_profile SIGHTING_METHOD_LAND, HauntedSightings
	sighting_profile SIGHTING_METHOD_LAND, IndustrialSightings
	sighting_profile SIGHTING_METHOD_LAND, VolcanicSightings
	sighting_profile SIGHTING_METHOD_LAND, IceCaveSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, SafariSightings
	sighting_profile SIGHTING_METHOD_LAND | SIGHTING_METHOD_WATER, EndgameSightings
	assert_table_length NUM_SIGHTING_PROFILES

NoWildSightings:
	db 0
EarlyGrasslandSightings:
	db 0
ForestSightings:
	db 0
RockyRouteSightings:
	db 0
MountainCaveSightings:
	db 0
UrbanOutskirtsSightings:
	db 0
WetlandSightings:
	db 0
CoastalSightings:
	db 0
OpenOceanSightings:
	db 0
HauntedSightings:
	db 0
IndustrialSightings:
	db 0
VolcanicSightings:
	db 0
IceCaveSightings:
	db 0
SafariSightings:
	db 0
EndgameSightings:
	db 0
