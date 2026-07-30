; super rod encounters
SuperRodData::
	; map, fishing group
	dbw PALLET_TOWN,         .Group1
	dbw VIRIDIAN_CITY,       .Group2
	dbw CERULEAN_CITY,       .Group3
	dbw VERMILION_CITY,      .Group4
	dbw CELADON_CITY,        .Group5
	dbw FUCHSIA_CITY,        .Group6
	dbw CINNABAR_ISLAND,     .Group7
	dbw ROUTE_4,             .Group8
	dbw ROUTE_6,             .Group9
	dbw ROUTE_24,            .Group10
	dbw ROUTE_25,            .Group11
	dbw ROUTE_10,            .Group12
	dbw ROUTE_11,            .Group13
	dbw ROUTE_12,            .Group14
	dbw ROUTE_13,            .Group15
	dbw ROUTE_17,            .Group16
	dbw ROUTE_18,            .Group17
	dbw ROUTE_19,            .Group18
	dbw ROUTE_20,            .Group19
	dbw ROUTE_21,            .Group20
	dbw ROUTE_22,            .Group21
	dbw ROUTE_23,            .Group22
	dbw VERMILION_DOCK,      .Group23
	dbw SAFARI_ZONE_CENTER,  .Group24
	dbw SAFARI_ZONE_EAST,    .Group25
	dbw SAFARI_ZONE_NORTH,   .Group26
	dbw SAFARI_ZONE_WEST,    .Group27
	dbw SEAFOAM_ISLANDS_B3F, .Group28
	dbw SEAFOAM_ISLANDS_B4F, .Group29
	dbw CERULEAN_CAVE_1F,    .Group30
	dbw CERULEAN_CAVE_B1F,   .Group31
	db -1 ; end

; fishing groups
; number of monsters, followed by level/monster pairs

.Group1:
	db 4
	db 25, STARYU
	db 25, TENTACOOL
	db 30, STARYU
	db 30, TENTACRUEL

.Group2:
	db 4
	db 15, POLIWAG
	db 20, POLIWAG
	db 25, POLIWAG
	db 30, POLIWAG

.Group3:
	db 4
	db 25, GOLDEEN
	db 30, GOLDEEN
	db 30, SEAKING
	db 40, SEAKING

.Group4:
	db 4
	db 25, TENTACOOL
	db 30, TENTACOOL
	db 30, KRABBY
	db 30, HORSEA

.Group5:
	db 4
	db 20, GOLDEEN
	db 25, GOLDEEN
	db 30, GOLDEEN
	db 25, GRIMER

.Group6:
	db 4
	db 5, MAGIKARP
	db 10, MAGIKARP
	db 15, MAGIKARP
	db 20, GYARADOS

.Group7:
	db 4
	db 35, STARYU
	db 35, TENTACOOL
	db 30, STARYU
	db 35, TENTACRUEL

.Group8:
	db 4
	db 30, GOLDEEN
	db 35, GOLDEEN
	db 30, SEAKING
	db 35, SEAKING

.Group9:
	db 4
	db 30, GOLDEEN
	db 35, GOLDEEN
	db 30, SEAKING
	db 35, SEAKING

.Group10:
	db 4
	db 35, GOLDEEN
	db 30, SEAKING
	db 35, SEAKING
	db 30, SEAKING

.Group11:
	db 4
	db 25, KRABBY
	db 30, KRABBY
	db 35, KINGLER
	db 15, DRATINI

.Group12:
	db 4
	db 25, KRABBY
	db 30, KRABBY
	db 30, HORSEA
	db 35, KINGLER

.Group13:
	db 4
	db 25, TENTACOOL
	db 25, TENTACOOL
	db 30, TENTACOOL
	db 35, HORSEA

.Group14:
	db 4
	db 30, HORSEA
	db 25, HORSEA
	db 30, SEADRA
	db 35, SEADRA

.Group15:
	db 4
	db 25, HORSEA
	db 30, HORSEA
	db 30, TENTACRUEL
	db 30, SEADRA

.Group16:
	db 4
	db 25, TENTACOOL
	db 30, TENTACOOL
	db 30, SHELLDER
	db 35, SHELLDER

.Group17:
	db 4
	db 25, TENTACOOL
	db 30, SHELLDER
	db 35, SHELLDER
	db 35, SHELLDER

.Group18:
	db 4
	db 25, TENTACOOL
	db 30, STARYU
	db 30, TENTACOOL
	db 35, TENTACRUEL

.Group19:
	db 4
	db 20, TENTACOOL
	db 20, TENTACRUEL
	db 30, STARYU
	db 40, TENTACRUEL

.Group20:
	db 4
	db 15, TENTACOOL
	db 20, STARYU
	db 30, TENTACOOL
	db 30, TENTACRUEL

.Group21:
	db 4
	db 10, POLIWAG
	db 15, POLIWAG
	db 20, POLIWAG
	db 25, POLIWHIRL

.Group22:
	db 4
	db 45, POLIWHIRL
	db 45, POLIWRATH
	db 45, OMANYTE
	db 45, KABUTO

.Group23:
	db 4
	db 30, TENTACOOL
	db 30, TENTACRUEL
	db 35, STARYU
	db 30, SHELLDER

.Group24:
	db 4
	db 20, MAGIKARP
	db 20, MAGIKARP
	db 20, DRATINI
	db 25, DRAGONAIR

.Group25:
	db 4
	db 25, MAGIKARP
	db 20, MAGIKARP
	db 25, DRATINI
	db 25, DRATINI

.Group26:
	db 4
	db 25, MAGIKARP
	db 20, MAGIKARP
	db 20, GYARADOS
	db 20, DRATINI

.Group27:
	db 4
	db 25, MAGIKARP
	db 20, MAGIKARP
	db 20, DRATINI
	db 20, DRATINI

.Group28:
	db 4
	db 35, KRABBY
	db 35, STARYU
	db 40, KINGLER
	db 40, STARYU

.Group29:
	db 4
	db 40, KRABBY
	db 40, STARYU
	db 40, KINGLER
	db 40, STARYU

.Group30:
	db 4
	db 55, SEAKING
	db 55, DEWGONG
	db 55, CLOYSTER
	db 55, GYARADOS

.Group31:
	db 4
	db 60, SEAKING
	db 60, STARMIE
	db 60, KABUTOPS
	db 60, OMASTAR
