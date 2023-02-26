
local new_pastable_entities = {}

for name, inserter in pairs(data.raw['inserter']) do
	inserter.allow_copy_paste = true
	table.insert(new_pastable_entities, name)
end

for name, machine in pairs(data.raw['assembling-machine']) do
	machine.additional_pastable_entities = new_pastable_entities
end

