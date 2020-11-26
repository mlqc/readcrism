FUNCTION SetUnion, a, b
  superset = [a, b]
  union = superset[Uniq(superset, Sort(superset))]
  RETURN, union
END