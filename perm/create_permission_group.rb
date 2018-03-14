#!/usr/bin/env ./script/runner
# encoding: utf-8

_source = 'artist'
_new_code = 'new_rule_set'
_new_name = 'New Rule Set'

#ca = PermissionRuleSet.find_by_code(_source)
nrs = PermissionRuleSet.create( :code=>_new_code, :display_name => _new_name, :entity_type => 'HumanUser')
nrs.import_rules(PermissionRuleSet.dump_rules(_source))

# nrs.permission_rules.create(:rule_type=>'update_field_condition', :allow=>'true', :parameter_1=>'Note', :parameter_2=>'addressings_cc', :retrieve_value=>'{"path":"id", "relation":"is_not","values":[0]}')

nrs.save;

puts nrs