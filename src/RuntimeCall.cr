require "./RuntimeCall/*"

module RuntimeCall
  alias Atom = Int64 | UInt64 | Int32 | UInt32 | Int16 | UInt16 | Int8 | UInt8 | Float64 | Float32 | String | Bool | Nil
  alias Comp = Array(Comp) | Hash(Comp, Comp) | Atom

  class UndefinedCall < Exception
  end

  # Defines a list of functions that are used to find operator, and defines `termine`.
  #
  # It makes the `termine` able to call the function by associating their name with a proc.
  macro extended
    alias RuntimeCallReturn = Proc(self, Array(String), RuntimeCall::Comp)
    RUNTIME_CALLS__ = Hash(String, RuntimeCallReturn).new

    # Read into the list of operators functions to call the right one.
    def runtime_call(call : String, values : Array(String)) : RuntimeCall::Comp
      call_proc = RUNTIME_CALLS__[call]?
      raise RuntimeCall::UndefinedCall.new %(No runtime call "#{call}" in (#{self.class})) if call_proc.nil?
      call_proc.call(self, values)
    end
  end

  # Defines getter with an unused parameter so it is compatible with the prototype used by __set_operators
  macro getter_runtime_call(*_calls)
    {% for _call in _calls %}
      RUNTIME_CALLS__[{{_call}}] = -> (obj : self, args : Array(String)) { obj._rt_{{_call.id}}(args) }

      def _rt_{{_call.id}}(values) : RuntimeCall::Comp
        RuntimeCall.__require_no_arguments({{_call}}, values)
        @{{_call.id}}.as(RuntimeCall::Comp)
      end
    {% end %}
  end

  # Define an operator compatible with __set_operators. It also check the type of the arguments.
  macro define_runtime_call(_call, *_types, &_block)
    RUNTIME_CALLS__[{{_call}}] = -> (obj : self, args : Array(String)) { obj._rt_{{_call.id}}(args) }

    def _rt_{{_call.id}}(values : Array(String)) : RuntimeCall::Comp
      {% if _types.empty? %}
        RuntimeCall.__require_no_arguments({{_call}}, values)
        {{yield}}.as(RuntimeCall::Comp)
      {% else %}
        args = RuntimeCall.__require_arguments({{_call}}, values, {{*_types}})
        {{yield args}}.as(RuntimeCall::Comp)
      {% end %}
    end
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
            {{_types[_i]}}.new({{values}}[{{_i}}])
          rescue err
            raise "Invalid (#{{{_i}}}th) argument (#{{{values}}[{{_i}}]}) in (#{{{context}}})"
          end
        ),
      {% end %}
    }
  end

  macro __require_no_arguments(context, values)
    raise "Invalid argument count in (#{{{context}}}) with arguments (#{{{values}}})" unless {{values}}.empty?
  end
end
