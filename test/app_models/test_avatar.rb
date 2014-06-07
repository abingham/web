#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/model_test_case'

class AvatarTests < ModelTestCase

  test 'avatar is not active? when it does not exist' do
    kata = @dojo.katas[id]
    lion = kata.avatars['lion']
    assert !lion.exists?
    assert !lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar is not active? when it has zero traffic-lights' do
    kata = @dojo.katas[id]
    lion = kata.avatars['lion']
    lights_filename = lion.traffic_lights_filename
    @paas.dir(lion).spy_read(lights_filename, JSON.unparse([]))
    assert !lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar is not active? when it has one traffic-light' do
    kata = @dojo.katas[id]
    lion = kata.avatars['lion']
    lights_filename = lion.traffic_lights_filename
    @paas.dir(lion).spy_read(lights_filename, JSON.unparse([
      {
        'colour' => 'red',
        'time' => [2014, 2, 15, 8, 54, 6],
        'number' => 1
      }
    ]))
    assert !lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar is active? when it has 2 or more traffic-lights' do
    kata = @dojo.katas[id]
    lion = kata.avatars['lion']
    lights_filename = lion.traffic_lights_filename
    @paas.dir(lion).spy_read(lights_filename, JSON.unparse([
      {
        'colour' => 'red',
        'time' => [2014, 2, 15, 8, 54, 6],
        'number' => 1
      },
      {
        'colour' => 'green',
        'time' => [2014, 2, 15, 8, 54, 34],
        'number' => 2
      }
      ]))
    assert lion.active?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exists? is true' +
       ' when dir exists' +
       ' and name is in Avatars.name' do
    json_and_rb do
      kata = @dojo.katas[id]
      lion = kata.avatars['lion']
      assert !lion.exists?
      @paas.dir(lion).make
      assert lion.exists?
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'exists? is false' +
       ' when dir exists' +
       ' and name is NOT in Avatars.name' do
    json_and_rb do
      kata = @dojo.katas[id]
      assert !Avatars.names.include?('salmon')
      salmon = kata.avatars['salmon']
      assert !salmon.exists?
      @paas.dir(salmon).make
      assert !salmon.exists?
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'avatar creation saves' +
          ' visible_files in avatar/manifest.rb|json,' +
          ' and empty avatar/increments.rb/json,' +
          ' and each visible_file into avatar/sandbox,' +
          ' and links each support_filename into avatar/sandbox' do
    json_and_rb do |format|
      language = @dojo.languages['C-assert']

      visible_files = {
        'wibble.h' => '#include <stdio.h>',
        'wibble.c' => '#include "wibble.h"'
      }
      visible_files.each do |filename,content|
        @paas.dir(language).spy_read(filename, content)
      end

      support_filename = 'lib.a'
      @paas.dir(language).spy_read('manifest.json', {
        :unit_test_framework => 'assert',
        :visible_filenames => visible_files.keys,
        :support_filenames => [ support_filename ]
      })
      exercise = @dojo.exercises['test_Yahtzee']
      @paas.dir(exercise).spy_read('instructions', 'your task...')

      kata = @dojo.make_kata(language, exercise)
      avatar = kata.start_avatar
      sandbox = avatar.sandbox

      visible_files.each do |filename,content|
        assert @paas.dir(sandbox).log.include?(['write',filename,content]),
          @paas.dir(sandbox).log.inspect
      end

      avatar = kata.start_avatar
      expected_manifest = { }
      visible_files.each do |filename,content|
        expected_manifest[filename] = content
      end
      expected_manifest['output'] = ''
      expected_manifest['instructions'] = 'your task...'

      if (format == 'rb')
        assert @paas.dir(avatar).log.include?(['write','manifest.rb', expected_manifest.inspect]),
            @paas.dir(avatar).log.inspect
        assert @paas.dir(avatar).log.include?(['write','increments.rb', [ ].inspect]),
            @paas.dir(avatar).log.inspect
      end
      if (format == 'json')
        assert @paas.dir(avatar).log.include?(['write','manifest.json', JSON.unparse(expected_manifest)]),
            @paas.dir(avatar).log.inspect
        assert @paas.dir(avatar).log.include?(['write','increments.json', JSON.unparse([ ])]),
            @paas.dir(avatar).log.inspect
      end

      expected_symlink = [
        'symlink',
        @paas.path(language) + support_filename,
        @paas.path(sandbox) + support_filename
      ]
      assert @disk.symlink_log.include?(expected_symlink), @disk.symlink_log.inspect
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - -

  test 'after test() output-file is not saved in sandbox ' +
       'and output-file is not inserted into the visible_files argument' do
    json_and_rb do
      kata = @dojo.katas['45ED23A2F1']
      avatar = kata.avatars['hippo']
      sandbox = avatar.sandbox
      visible_files = {
        'untitled.c' => 'content for code file',
        'untitled.test.c' => 'content for test file',
        'cyber-dojo.sh' => 'make'
      }
      assert !visible_files.keys.include?('output')
      delta = {
        :changed => [ 'untitled.c' ],
        :unchanged => [ 'untitled.test.c' ],
        :deleted => [ ],
        :new => [ ]
      }
      avatar.save(delta, visible_files)
      output = avatar.test(@max_duration)
      assert_equal 'stubbed-output', output
      assert !visible_files.keys.include?('output')
      saved_filenames = filenames_written_to_in(@paas.dir(sandbox).log)
      assert !saved_filenames.include?('output')
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'save():delta[:changed] files are saved' do
    json_and_rb do
      avatar = @dojo.katas['45ED23A2F1'].avatars['hippo']
      sandbox = avatar.sandbox
      visible_files = {
        'untitled.cs' => 'content for code file',
        'untitled.test.cs' => 'content for test file',
        'cyber-dojo.sh' => 'gmcs'
      }
      delta = {
        :changed => [ 'untitled.cs', 'untitled.test.cs'  ],
        :unchanged => [ ],
        :deleted => [ ],
        :new => [ ]
      }
      avatar.save(delta, visible_files)
      output = avatar.test(@max_duration)
      log = @paas.dir(sandbox).log
      saved_filenames = filenames_written_to_in(log)
      assert_equal delta[:changed].sort, saved_filenames.sort
      assert log.include?(['write','untitled.cs', 'content for code file' ]), log.inspect
      assert log.include?(['write','untitled.test.cs', 'content for test file' ]), log.inspect
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'save():delta[:unchanged] files are not saved' do
    json_and_rb do
      avatar = @dojo.katas['45ED23A2F1'].avatars['hippo']
      sandbox = avatar.sandbox
      visible_files = {
        'untitled.cs' => 'content for code file',
        'untitled.test.cs' => 'content for test file',
        'cyber-dojo.sh' => 'gmcs'
      }
      delta = {
        :changed => [ 'untitled.cs' ],
        :unchanged => [ 'cyber-dojo.sh', 'untitled.test.cs' ],
        :deleted => [ ],
        :new => [ ]
      }
      avatar.save(delta, visible_files)
      saved_filenames = filenames_written_to_in(@paas.dir(sandbox).log)
      assert_equal delta[:changed].sort, saved_filenames
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'save():delta[:new] files are saved and git added' do
    json_and_rb do
      avatar = @dojo.katas['45ED23A2F1'].avatars['hippo']
      sandbox = avatar.sandbox
      visible_files = {
        'wibble.cs' => 'content for code file',
        'untitled.test.cs' => 'content for test file',
        'cyber-dojo.sh' => 'gmcs'
      }
      delta = {
        :changed => [ ],
        :unchanged => [ 'cyber-dojo.sh', 'untitled.test.cs' ],
        :deleted => [ ],
        :new => [ 'wibble.cs' ]
      }
      avatar.save(delta, visible_files)
      saved_filenames = filenames_written_to_in(@paas.dir(sandbox).log)
      assert_equal delta[:new].sort, saved_filenames.sort
      git_log = @git.log[@paas.path(sandbox)]
      assert git_log.include?([ 'add', 'wibble.cs' ]), git_log.inspect
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "save():delta[:deleted] files are git rm'd" do
    json_and_rb do
      avatar = @dojo.katas['45ED23A2F1'].avatars['hippo']
      sandbox = avatar.sandbox
      visible_files = {
        'untitled.cs' => 'content for code file',
        'untitled.test.cs' => 'content for test file',
        'cyber-dojo.sh' => 'gmcs'
      }
      delta = {
        :changed => [ 'untitled.cs' ],
        :unchanged => [ 'cyber-dojo.sh', 'untitled.test.cs' ],
        :deleted => [ 'wibble.cs' ],
        :new => [ ]
      }
      avatar.save(delta, visible_files)
      saved_filenames = filenames_written_to_in(@paas.dir(sandbox).log)
      assert !saved_filenames.include?('wibble.cs'), saved_filenames.inspect

      git_log = @git.log[@paas.path(sandbox)]
      assert git_log.include?([ 'rm', 'wibble.cs' ]), git_log.inspect
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - -

=begin

  test 'avatar (rb) creation sets up initial git repo of visible files ' +
        '(but support_files are not in git repo)' do
    @dojo = Dojo.new('spied/','rb')
    @kata = @dojo[@id]
    visible_files = {
      'name' => 'content for name'
    }
    language = @dojo.language('C')
    manifest = {
      :id => @id,
      :visible_files => visible_files,
      :language => language.name
    }
    kata_manifest_spy_read('rb',manifest)
    language.dir.spy_read('manifest.json', JSON.unparse({ }))
    kata = @dojo.create_kata(manifest)
    avatar = kata.start_avatar

    git_log = @git.log[avatar.path]
    assert_equal [ 'init', '--quiet'], git_log[0]
    add1_index = git_log.index([ 'add', 'increments.rb' ])
    assert add1_index != nil
    add2_index = git_log.index([ 'add', 'manifest.rb'])
    assert add2_index != nil
    commit1_index = git_log.index([ 'commit', "-a -m '0' --quiet" ])
    assert commit1_index != nil
    commit2_index = git_log.index([ 'commit', "-m '0' 0 HEAD" ])
    assert commit2_index != nil

    assert add1_index < commit1_index
    assert add1_index < commit2_index
    assert add2_index < commit1_index
    assert add2_index < commit2_index

    assert_equal [
      [ 'add', 'name']
    ], @git.log[avatar.sandbox.path], @git.log.inspect

    assert avatar.dir.log.include?([ 'write', 'manifest.rb', visible_files.inspect ]), avatar.dir.log.inspect
    assert avatar.dir.log.include?([ 'write', 'increments.rb', [ ].inspect ]), avatar.dir.log.inspect
    assert kata.dir.log.include?([ 'write','manifest.rb', manifest.inspect ]), kata.dir.log.inspect
    assert kata.dir.log.include?([ 'read','manifest.rb',manifest.inspect ]), kata.dir.log.inspect
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "avatar (json) creation sets up initial git repo of visible files " +
        "but not support_files" do
    @dojo = Dojo.new('spied/','json')
    @kata = @dojo[@id]
    visible_files = {
      'name' => 'content for name'
    }
    language = @dojo.language('C')
    manifest = {
      :id => @id,
      :visible_files => visible_files,
      :language => language.name
    }
    kata_manifest_spy_read('json',manifest)
    language.dir.spy_read('manifest.json', JSON.unparse({ }))
    kata = @dojo.create_kata(manifest)
    avatar = kata.start_avatar

    git_log = @git.log[avatar.path]
    assert_equal [ 'init', '--quiet'], git_log[0]
    add1_index = git_log.index([ 'add', 'increments.json' ])
    assert add1_index != nil
    add2_index = git_log.index([ 'add', 'manifest.json'])
    assert add2_index != nil
    commit1_index = git_log.index([ 'commit', "-a -m '0' --quiet" ])
    assert commit1_index != nil
    commit2_index = git_log.index([ 'commit', "-m '0' 0 HEAD" ])
    assert commit2_index != nil

    assert add1_index < commit1_index
    assert add1_index < commit2_index
    assert add2_index < commit1_index
    assert add2_index < commit2_index

    assert_equal [
      [ 'add', 'name']
    ], @git.log[avatar.sandbox.path], @git.log.inspect

    assert avatar.dir.log.include?([ 'write', 'manifest.json', JSON.unparse(visible_files)]), avatar.dir.log.inspect
    assert avatar.dir.log.include?([ 'write', 'increments.json', JSON.unparse([ ])]), avatar.dir.log.inspect
    assert kata.dir.log.include?([ 'write','manifest.json', JSON.unparse(manifest)]), kata.dir.log.inspect
    assert kata.dir.log.include?([ 'read','manifest.json', JSON.unparse(manifest)]), kata.dir.log.inspect
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "avatar has no traffic-lights before first test-run" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name'
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      assert_equal [ ], avatar.traffic_lights
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "avatar returns kata it was created with" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name'
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      assert_equal kata, avatar.kata
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "avatar's tag 0 repo contains an empty output file only when kata-manifest does" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name',
        'output' => ''
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      visible_files = avatar.visible_files
      assert visible_files.keys.include?('output'),
            "visible_files.keys.include?('output')"
      assert_equal "", visible_files['output']
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "after avatar is created sandbox contains separate visible_files" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name',
        'output' => ''
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      visible_files.each do |filename,content|
        assert_equal content, avatar.sandbox.dir.read(filename)
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "after avatar is created avatar dir contains all visible_files in manifest" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name',
        'output' => ''
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      avatar.visible_files.each do |filename,content|
        assert visible_files.keys.include?(filename)
        assert_equal visible_files[filename], content
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "after avatar is created sandbox contains cyber-dojo.sh" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/',format)
      @kata = @dojo[@id]
      visible_files = {
        'name' => 'content for name',
        'cyber-dojo.sh' => 'make'
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({ }))
      kata = @dojo.create_kata(manifest)
      avatar = kata.start_avatar
      sandbox = avatar.sandbox
      assert_equal visible_files['cyber-dojo.sh'], sandbox.dir.read('cyber-dojo.sh')
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "after first test() traffic_lights contains one traffic-light " +
        "which does not contain output" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/', format)
      @kata = @dojo[@id]
      visible_files = {
        'untitled.c' => 'content for visible file',
        'cyber-dojo.sh' => 'make',
      }
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :visible_files => visible_files,
        :language => language.name
      }
      kata_manifest_spy_read(format,manifest)
      kata = @dojo.create_kata(manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({
          "visible_files" => visible_files,
          "unit_test_framework" => "cassert"
        }))
      avatar = @kata.start_avatar
      avatar.sandbox.dir.spy_write('untitled.c', 'content for visible file')
      avatar.sandbox.dir.spy_write('cyber-dojo.sh', 'make')
      delta = {
        :changed => [ 'untitled.c' ],
        :unchanged => [ 'cyber-dojo.sh' ],
        :deleted => [ 'wibble.cs' ],
        :new => [ ]
      }
      avatar.sandbox.write(delta, avatar.visible_files)
      output = avatar.sandbox.test(timeout=15)
      visible_files['output'] = output
      avatar.save_visible_files(visible_files)

      traffic_light = OutputParser::parse(@kata.language.unit_test_framework, output)
      traffic_lights = avatar.save_traffic_light(traffic_light, make_time(Time.now))
      assert_equal 1, traffic_lights.length
      assert_equal nil, traffic_lights.last[:run_tests_output]
      assert_equal nil, traffic_lights.last[:output]
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "one more traffic light each test() call" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/', format)
      @kata = @dojo[@id]
      language = @dojo.language('C')
      manifest = {
        :id => @id,
        :language => language.name,
        :visible_files => [ ]
      }
      kata_manifest_spy_read(format,manifest)
      @kata = @dojo.create_kata(manifest)
      language.dir.spy_read('manifest.json', JSON.unparse({
          "visible_files" => [ ],
          "unit_test_framework" => "cassert"
        }))
      avatar = @kata.start_avatar
      output = 'stubbed'
      traffic_light = OutputParser::parse('cassert', output)
      traffic_lights = avatar.save_traffic_light(traffic_light, make_time(Time.now))
      assert_equal 1, traffic_lights.length
      traffic_light = OutputParser::parse('cassert', output)
      traffic_lights = avatar.save_traffic_light(traffic_light, make_time(Time.now))
      assert_equal 2, traffic_lights.length
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "diff_lines" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/', format)
      @kata = @dojo[@id]
      avatar = @kata['lion']
      output = avatar.diff_lines(was_tag=3,now_tag=4)
      assert @git.log[avatar.path].include?(
        [
         'diff',
         '--ignore-space-at-eol --find-copies-harder 3 4 sandbox'
        ])
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test "locked_read with tag" do
    json_and_rb |format|
      @dojo = Dojo.new('spied/', format)
      @kata = @dojo[@id]
      avatar = @kata['lion']
      output = avatar.visible_files(tag=4)
      assert @git.log[avatar.path].include?(
        [
         'show',
         '4:manifest.rb'
        ])
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_manifest_spy_read(format, manifest)
    if format == 'rb'
      @paas.dir(@kata).spy_read('manifest.rb', manifest.inspect)
    end
    if format == 'json'
      @paas.dir(@kata).spy_read('manifest.json', JSON.unparse(manifest))
    end
  end

=end

  def id
    '45ED23A2F1'
  end

end
