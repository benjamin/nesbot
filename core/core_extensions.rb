class Array
  # If +number+ is greater than the size of the array, the method
  # will simply return the array itself sorted randomly
  def randomly_pick(number)
    a = sort_by{ rand }.slice(0...number)
    return a.size() > 1 ? a : a[0]
  end
end

# Easily print methods local to an object's class - useful for the plugins
class Object
  def local_methods
    (methods - Object.instance_methods).sort
  end
end