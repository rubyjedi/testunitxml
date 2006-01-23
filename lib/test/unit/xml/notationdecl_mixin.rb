module REXML
  class NotationDecl
    def name
      @name
    end
    
    #TODO: Fix system and public - @rest may contain both public and system identifier
    def system
      parse_rest(@rest)[1]
    end
    
    def public
      return nil unless @middle == "PUBLIC"
      parse_rest(@rest)[0]
    end
    
    private
    
    def parse_rest(rest)
      case rest
      when /^"([^"]+)"\s+"([^"]+)"$/
        return [$1,$2]
      when /^'([^']+)'\s+'([^']+)'$/
        return [$1,$2]
      when /^"([^"]+)"\s+'([^']+)'$/
        return [$1,$2]
      when /^'([^']+)'\s+"([^"]+)"$/
        return [$1,$2]
      when /^"([^"]+)"$/
        return [nil, $1] if @middle == 'SYSTEM'
        return [$1, nil] if @middle == 'PUBLIC'
        raise "Unknown notation keyword: #{@middle}"
      when /^'([^']+)'$/
        return [nil, $1] if @middle == 'SYSTEM'
        return [$1, nil] if @middle == 'PUBLIC'
        raise "Unknown notation keyword: #{@middle}"
      else
        raise "Could not parse \@rest variable in REXML::NotationDecl: |#{@rest}|"
      end
    end
  end

end