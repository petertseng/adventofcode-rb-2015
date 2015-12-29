class Bst
  module NilBst refine NilClass do
    def <<(val)
      Bst.new(val)
    end
  end end

  using NilBst

  def initialize(data = nil)
    @data = data
    @left = nil
    @right = nil
  end

  def max
    max_node&.data
  end

  def each(&block)
    @left&.each(&block)
    block[@data] unless @data.nil?
    @right&.each(&block)
  end

  def <<(val)
    if @data.nil?
      @data = val
    elsif val <= @data
      @left <<= val
    else
      @right <<= val
    end
    self
  end

  def concat(xs)
    xs.each { |x| self << x }
  end

  # This implementation of delete leaves a lot of nodes with nil @data lying around,
  # but it doesn't seem to particularly matter.
  def delete(val)
    return if @data.nil?

    case val <=> @data
    when -1
      @left&.delete(val)
      # could set @left to nil here if @left was a singleton
    when 1
      @right&.delete(val)
      # could set @right to nil here if @right was a singleton
    when 0
      if @left&.data && @right&.data
        max_node = @left.max_node
        @data = max_node.data
        max_node.delete(@data)
        # could max_node's parent's right to nil if max_node was a singleton
      elsif @left&.data
        @data = @left.data
        @right = @left.right
        @left = @left.left
      elsif @right&.data
        @data = @right.data
        @left = @right.left
        @right = @right.right
      else
        @data = nil
      end
    else
      raise "incomparable val #{val} dat #@data"
    end
  end

  protected

  def max_node
    current = self
    current = current.right while current.right&.data
    current
  end

  def max_node_and_parent
    prev = nil
    current = self
    while current.right&.data
      prev = current
      current = current.right
    end
    [current, prev]
  end

  attr_reader :data, :left, :right
end
