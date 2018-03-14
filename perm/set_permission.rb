#!/usr/bin/env ./script/runner
# encoding: utf-8
#$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))
require 'yaml'

puts "rule_lib included"

class RuleBase
	def initialize(para={})

		_input0 = ARGV[0]
		_input1 = ARGV[1]

		if _input0 != "" and _input0 != nil
			@rule_yml  = File.join(File.dirname(File.expand_path(__FILE__)), _input0)
		else
			puts
			puts "Missing rules.yml"
			puts "sudo docker-compose run --rm app script/rb/set_permission.rb rules.yml --create|--delete|rule_id"
			puts
			exit
		end

		if _input1.to_i > 0
			@rule_id = _input1.to_i
		else
			if _input1.is_a? String
				if _input1 == "--create" or _input1 == "--delete"
					if _input1 == "--create"
						@act = "create"
					else
						@act = "delete"
					end
				else
					puts
					puts "Missing action"
				    puts "sudo docker-compose run --rm app script/rb/set_permission.rb rules.yml --create|--delete|rule_id"
					puts
					exit
				end
			end
		end

	    setup
	end

	def setup()
		@rules = YAML.load_file(@rule_yml)
		@role = @rules["permission_group"]
		@nrs = PermissionRuleSet.find_by_code(@role)

		if @rule_id.is_a? Numeric 
			if @rule_id >0 
				show_rule
				exit
			end
		end
	end

	def set_rules()
		@rules['rules'].each_with_index do |sub_rules, index|
			sub_rules.each_with_index do |rs, i|
				if !rs.instance_of?(String)
					rs.each do |r|
						if !r.instance_of?(String)
							r.each do |m|
								if !m.instance_of?(String)
								    @rule_type = m["rule_type"]
									@parameter_1 = m["parameter_1"] == '' ? nil : m["parameter_1"]
									@parameter_2 = m["parameter_2"] == '' ? nil : m["parameter_2"]
									@parameter_3 = m["parameter_3"] == '' ? nil : m["parameter_3"]
									@parameter_4 = m["parameter_4"] == '' ? nil : m["parameter_4"]
									@allow = m["allow"];
									@retrieve_value = m["retrieve_value"]== '' ? nil : m["retrieve_value"]
									
									if @act == "create"
									  create
									else
									  destroy
									end
								end
							end
						end
					end
				end
			end
		end
	end

	def show_rule()
		puts
		@nrs.permission_rules.each do |r|
			if r.attributes["id"] == @rule_id
				puts "Detail of the rule"
				show_para(r)
			end
		end
		puts
	end

	def create()
		rule_id = validate()
		if rule_id == nil
			puts "The rule is not existed. Creating ..."
			rule = @nrs.permission_rules.create(:rule_type=>@rule_type, :allow=>@allow, :parameter_1=>@parameter_1, :parameter_2=>@parameter_2, :parameter_3=>@parameter_3, :parameter_4=>@parameter_4, :retrieve_value=>@retrieve_value)
			@nrs.save
			puts rule
			puts "Rule is created."
		else
			puts "The rule #{rule_id} is existed."
		end
		puts
	end

	def destroy()
		rule_id = validate()
		if rule_id != nil
			puts "Delete #{rule_id}"
			@nrs.permission_rules.destroy(rule_id)
			@nrs.save
		else
			puts "The rule is not existed."
		end
		puts
	end

	def validate()
		puts "Validating if the rule exist ..."
		@nrs.permission_rules.each do |r|
			if @parameter_2 == nil && @parameter_3 == nil && @parameter_4 == nil
				if r.attributes["rule_type"] == @rule_type && r.attributes["parameter_1"] == @parameter_1
				  show_para(r)
				  return r.attributes["id"]
				end
			elsif @parameter_3 == nil && @parameter_4 == nil
				if r.attributes["rule_type"] == @rule_type && r.attributes["parameter_1"] == @parameter_1 && r.attributes["parameter_2"] == @parameter_2
				  show_para(r)
				  return r.attributes["id"]
				end
			elsif @parameter_3 == nil
				if r.attributes["rule_type"] == @rule_type && r.attributes["parameter_1"] == @parameter_1 && r.attributes["parameter_2"] == @parameter_2 && r.attributes["parameter_3"] == @parameter_3
				  show_para(r)
				  return r.attributes["id"]
				end
			else
				if r.attributes["rule_type"] == @rule_type && r.attributes["parameter_1"] == @parameter_1 && r.attributes["parameter_2"] == @parameter_2 && r.attributes["parameter_3"] == @parameter_3 && r.attributes["parameter_4"] == @parameter_4
				  show_para(r)
				  return r.attributes["id"]
				end
			end
		end
		puts "Can't find the rule."
		return nil
	end

	def show_para(r)
		puts "Rule ID: #{r.attributes["id"]}"
		show_detail(para_name:"parameter_1", para_value:r.attributes["parameter_1"])
		show_detail(para_name:"parameter_2", para_value:r.attributes["parameter_2"])
		show_detail(para_name:"parameter_3", para_value:r.attributes["parameter_3"])
		show_detail(para_name:"parameter_4", para_value:r.attributes["parameter_4"])
		show_detail(para_name:"Allow", para_value:r.attributes["allow"])
		show_detail(para_name:"Retrieve Value", para_value:r.attributes["retrieve_value"])
	end

	def show_detail(settings={})
		para_name=settings[:para_name]
		para_value=settings[:para_value]

		if para_value == nil
			puts "#{para_name}: nil"
		elsif para_value == ""
			puts "#{para_name}: "
		else
			puts "#{para_name}: #{para_value}"
		end
	end
end

rule=RuleBase.new()
rule.set_rules()
