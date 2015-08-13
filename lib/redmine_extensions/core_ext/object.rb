class Object

  def nested_send(symbol)
    return __send__(symbol) if respond_to?(symbol)
    obj = nil
    symbol.to_s.split('.').each do |part|
      nested_symbol = part.to_sym
      if obj
        break unless obj.respond_to?(nested_symbol)
        obj = obj.__send__(nested_symbol)
      else
        break unless respond_to?(nested_symbol)
        obj = __send__(nested_symbol)
      end
    end
    obj
  end

end
