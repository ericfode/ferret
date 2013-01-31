class Hash
  def rmerge!(h)
    replace(h.merge(self))
  end
end
