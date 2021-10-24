package igloo.logger;

@:forward(message, timestamp, level) abstract Message(MessageDefinition) from MessageDefinition
{
	@:op(a.b) public function setField(_field : String, _value : Any)
    {
        Reflect.setField(this, _field, _value);
	}

	@:op(a.b) public function getField(_field : String)
    {
		return Reflect.field(this, _field);
	}

	public function toString() {
		return '[${ this.timestamp }][${ this.level }]${ this.message }';
	}
}