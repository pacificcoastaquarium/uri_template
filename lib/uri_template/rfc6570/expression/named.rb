# -*- encoding : utf-8 -*-
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the Affero GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    (c) 2011 - 2012 by Hannes Georg
#

require 'uri_template/rfc6570'

class URITemplate::RFC6570

class Expression::Named < Expression

  alias self_pair pair

  def to_r_source
    source = regex_builder
    source.group do
      source.escaped_prefix
      first = true
      @variable_specs.each do | var, expand , max_length |
        if expand
          source.capture do
            source.separated_list(first) do
              source.character_class('+')\
                .escaped_pair_connector\
                .character_class_with_comma(max_length)
            end
          end
        else
          source.group do
            source.escaped_separator unless first
            source << Regexp.escape(var)
            source.group do
              source.escaped_pair_connector
              source.capture do
                source.character_class_with_comma(max_length)
              end
              source << '|' unless self.class::PAIR_IF_EMPTY
            end
          end.length('?')
        end
        first = false
      end
    end.length('?')
    return source.join
  end

  def expand_partial( vars )
    result = []
    rest   = []
    defined = false
    @variable_specs.each do | var, expand , max_length |
      if vars.key? var
        if Utils.def? vars[var]
          if result.any? && !self.class::SEPARATOR.empty?
            result.push( Literal.new(self.class::SEPARATOR) )
          end
          one = expand_one(var, vars[var], expand, max_length)
          result.push( Literal.new(Array(one).join(self.class::SEPARATOR)) )
        end
        if expand
          rest << [var, expand, max_length]
        else
          result.push( self.class::FOLLOW_UP.new([[var,expand,max_length]]) )
        end
      else
        rest.push( [var,expand,max_length] )
      end
    end
    if result.any?
      unless self.class::PREFIX.empty? || empty_literals?( result )
        result.unshift( Literal.new(self.class::PREFIX) )
      end
      result.push( self.class::BULK_FOLLOW_UP.new(rest) ) if rest.size != 0
      return result
    else
      return [ self ]
    end
  end

private

  def extracted_nil
    self.class::PAIR_IF_EMPTY ? nil : ""
  end

  def after_expand(name, splitted)
    result = URITemplate::Utils.pair_array_to_hash2( splitted )
    if result.size == 1 && result[0][0] == name
      return result
    else
      return [ [ name , result ] ]
    end
  end

end
end
