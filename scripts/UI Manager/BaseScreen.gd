extends Control

class_name BaseScreen

#if true screen captures input and blocks gameplay underneath
@export var modal: bool = true;

func open(args := {}): pass

func close():pass

func handle_back() -> bool:
	return false
