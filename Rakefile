# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'steep/rake_task'

RuboCop::RakeTask.new
Steep::RakeTask.new

task default: %i[rubocop steep]
