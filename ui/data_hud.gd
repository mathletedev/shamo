extends Control

@onready var address_label := $Address
@onready var hash_label := $Hash


func _on_chunk_changed(chunk: Chunk):
	address_label.text = "Address: " + chunk.address
	hash_label.text = "Hash: " + chunk.digest.hex_encode()
