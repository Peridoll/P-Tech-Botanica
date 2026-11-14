-- Merge these entries into ox_inventory/data/items.lua's returned table.
-- Do not replace the existing items file.
  ['ptech_botanica_hokuto_carton'] = {
    label = 'HOKUTO カートン', weight = 140, stack = false, close = true, consume = 0,
    client = { export = 'ptech_botanica_tobacco.unpackCarton' },
    description = 'HOKUTOの煙草が5箱入ったカートン。',
  },
  ['ptech_botanica_hokuto_box'] = {
    label = 'HOKUTO', weight = 28, stack = false, close = true, consume = 0,
    client = { export = 'ptech_botanica_tobacco.useCigaretteBox' },
    description = '全10本。使用するたびに1本消費する。',
  },
  ['ptech_botanica_archimedes_carton'] = {
    label = 'ARCHIMEDES カートン', weight = 140, stack = false, close = true, consume = 0,
    client = { export = 'ptech_botanica_tobacco.unpackCarton' },
    description = 'ARCHIMEDESの煙草が5箱入ったカートン。',
  },
  ['ptech_botanica_archimedes_box'] = {
    label = 'ARCHIMEDES', weight = 28, stack = false, close = true, consume = 0,
    client = { export = 'ptech_botanica_tobacco.useCigaretteBox' },
    description = '全10本。使用するたびに1本消費する。',
  },
  ['ptech_botanica_disposable_lighter'] = {
    label = '使い捨てライター', weight = 25, stack = false, close = true, consume = 0,
    description = '20回点火できる使い捨てライター。',
  },
