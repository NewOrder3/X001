class_name OfflineSettlementPanel
extends PanelContainer

## Presentation-only summary shown after GameSession activates a loaded save.

@onready var _summary_label: Label = %OfflineSettlementSummaryLabel
@onready var _close_button: Button = %OfflineSettlementCloseButton


func _ready() -> void:
	_close_button.pressed.connect(hide)
	hide()


func show_report(report: OfflineSettlementReport) -> void:
	if report == null or not report.succeeded or report.elapsed_seconds <= 0:
		hide()
		return
	_summary_label.text = _get_summary_text(report)
	show()


func _get_summary_text(report: OfflineSettlementReport) -> String:
	var hours: int = report.elapsed_seconds / 3600
	var minutes: int = report.elapsed_seconds % 3600 / 60
	var time_text: String = "%d 小时" % hours
	if minutes > 0:
		time_text = "%s %d 分钟" % [time_text, minutes]
	var supply_change: float = report.supply_after - report.supply_before
	var stamina_change: int = report.stamina_after - report.stamina_before
	return "离线 %s\n补给：%.1f（%+.1f）\n耐久：%.1f\n体力：%d（%+d）" % [
		time_text,
		report.supply_after,
		supply_change,
		report.durability_after,
		report.stamina_after,
		stamina_change,
	]
