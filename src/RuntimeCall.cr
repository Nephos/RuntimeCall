require "./RuntimeCall/*"

module RuntimeCall
  class UndefinedCall < Exception
  end

  # Defines a list of functions that are used to find operator, and defines `termine`.
  #
  # It makes the `termine` able to call the function by associating their name with a proc.
  macro extended
    alias RuntimeCallArg = String
    alias RuntimeCallArgsContainer = Array
    alias RuntimeCallArgs = RuntimeCallArgsContainer(RuntimeCallArg)

    RUNTIME_FUNCTIONS__ = [] of String

    # Read into the list of operators functions to call the right one.
    def runtime_call(call : String, values : RuntimeCallArgs)
      call_proc = RUNTIME_CALLS__[call]?
      raise RuntimeCall::UndefinedCall.new %(No runtime call "#{call}" in (#{self.class})) if call_proc.nil?
      call_proc.call(self, values)
    end

    def runtime_call(call : String, *values)
      call_proc = RUNTIME_CALLS__[call]?
      raise RuntimeCall::UndefinedCall.new %(No runtime call "#{call}" in (#{self.class})) if call_proc.nil?
      if values.size == 0
        call_proc.call self, [] of String
      else
        call_proc.call self, Array(String).new(values.size) { |i| values[i].to_s }
      end
    end
  end

  # Define an operator compatible with __set_operators. It also check the type of the arguments.
  macro define_runtime_call(_call, *_types, &_block)
    def _rt_{{_call.id}}(values : RuntimeCallArgs)
      {% if _types.empty? %}
        RuntimeCall.__require_no_arguments({{_call}}, values)
        {{yield}}
      {% else %}
        args = RuntimeCall.__require_arguments({{_call}}, values, {{*_types}})
        {{yield args}}
      {% end %}
    end
    {{RUNTIME_FUNCTIONS__ << _call}}
  end

  # Defines getter with an unused parameter so it is compatible with the prototype used by __set_operators
  macro getter_runtime_call(*_calls)
    {% for _call in _calls %}
      define_runtime_call({{_call}}) do
        @{{_call.id}}
      end
    {% end %}
  end

  macro finish_runtime_call
    RUNTIME_CALLS__ = {
      {% for _call in RUNTIME_FUNCTIONS__ %}
        {{_call}} => -> (on : self, args : RuntimeCallArgs) { on._rt_{{_call.id}}(args) },
      {% end %}
    }
  end

  # ```
  # arg1, arg2 = __require_arguments("my_function", UInt32, String)
  # ```
  macro __require_arguments(context, values, *_types)
    raise "Invalid argument count in (#{{{context}}}) with arguments (#{{{values}}})" if {{values}}.size != {{_types.size}}
    {
      {% for _i in 0..._types.size %}
        (
          begin
            {% if _types[_i].stringify == "String" %}
              {{_types[_i]}}.new({{values}}[{{_i}}].to_slice)
            {% else %}
              {{_types[_i]}}.new({{values}}[{{_i}}])
            {% end %}
          rescue err
            raise "Invalid (#{{{_i}}}th) argument (#{{{values}}[{{_i}}]}) in (#{{{context}}})"
          end
        ),
      {% end %}
    }
  end

  macro __require_no_arguments(context, values)
    raise "Invalid argument count in (#{{{context}}}) with arguments (#{{{values}}})" unless {{values}}.size == 0
  end

  macro extends(&block)
    extend RuntimeCall
    {{yield}}
    finish_runtime_call
  end
end
