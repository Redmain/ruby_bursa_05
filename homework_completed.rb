# условия, интежер, стринг

# Создать программу которая ищет точку в указаных координатах

# 1) входящие параметры - координаты расположения точки, которую нужно найти
# 2) метод для ввода данных с клавиатуры
# 3) 

require 'pry'

x, y, x_person, y_person = ARGV

if x_person == x && y_person == y
  puts 'Точка найдена'
elsif x_person == x && y_person != y
  puts 'х координата верна, y нет'
elsif x_person != x && y_person == y
  puts 'y координата верна, x нет'
else
  puts 'Близко, но нет'
end


def test
  w = `ruby homework.rb 10 12 10 12`
  binding.pry
end