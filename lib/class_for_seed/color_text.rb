class ColorText

  def initialize(text, result)
    @color_id = [95, 91, 35, 34, 33, 32, 31].sample
    @result = result
    @text = if @result.kind_of?(Array)
              if @result.empty?
                "#{text} isn`t created =("
              else
                "#{text} were created. (#{@result.count} created)"
              end
            else
              text
            end
  end

  def set_color
    "\033[#{@color_id}m\033[4m#{@text}\033[0m"
  end

  def hm_is_interesting
    puts set_color
    @result
  end

  def self.set_color text, result=nil
    new(text, result).hm_is_interesting
  end
end