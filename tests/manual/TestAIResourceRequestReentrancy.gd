extends Node

const SimpleClairvoyantAI = preload(
	"res://source/match/players/simple-clairvoyant-ai/SimpleClairvoyantAI.gd"
)


class FakeController:
	extends RefCounted

	var provisions = []

	func provision(resources, metadata):
		provisions.append({"resources": resources, "metadata": metadata})


func _ready():
	var ai = SimpleClairvoyantAI.new()
	var controller = FakeController.new()
	var resources = {"resource_a": 3, "resource_b": 1}
	ai.resource_a = 3
	ai.resource_b = 1

	ai._provisioning_ongoing = true
	ai._on_resource_request(
		resources,
		"reentrant_test_request",
		controller,
		ai.ResourceRequestPriority.HIGH
	)
	assert(
		controller.provisions.is_empty(),
		"AI should not fulfil reentrant resource requests in the same provisioning stack"
	)
	assert(
		ai._resource_requests[ai.ResourceRequestPriority.HIGH].size() == 1,
		"AI should queue reentrant resource requests"
	)
	assert(
		ai._call_to_perform_during_process != null,
		"AI should defer queued reentrant requests to process"
	)

	ai._provisioning_ongoing = false
	ai._process(0.0)
	assert(
		controller.provisions.size() == 1,
		"AI should fulfil deferred reentrant requests once provisioning finishes"
	)
	assert(
		controller.provisions[0]["metadata"] == "reentrant_test_request",
		"AI should preserve reentrant request metadata"
	)
	assert(
		ai._resource_requests[ai.ResourceRequestPriority.HIGH].is_empty(),
		"AI should remove fulfilled reentrant requests from the queue"
	)
	get_tree().quit()
