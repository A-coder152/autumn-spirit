class_name Item extends Resource

enum effects {
	LEAVES_GAIN, LEAVES_MAX,
	HAPPINESS_MAX, HAPPINESS_DRAIN, HAPPINESS_REST,
	REST_MAX, REST_DRAIN, REST_GAIN, REST_UNHAPPY,
	LONELINESS_TIME
}

enum types {
	MAT, COUCH, DECOR, PAINT, IDK,
	HEAD, ARM, LEG
}

@export var item_name: String
@export var desc: String
@export var image: Texture2D
@export var cost: int
@export var type: types
@export var effect: effects
@export var impact: float
