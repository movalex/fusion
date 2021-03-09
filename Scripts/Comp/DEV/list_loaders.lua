print("\n___________loaders__________")
for _, ld in pairs(bmd.GetLoaders(comp)) do print(ld.Name, ' ', ld.Clip[1]) end
print("\n___________savers__________")
for _, ld in pairs(bmd.GetSavers(comp)) do print(ld.Name, ' ', ld.Clip[1]) end
