require 'spec_helper'

describe Morph::CodeTranslate do
  describe ".translate" do
    let(:code) { double }

    it "should translate ruby" do
      expect(Morph::CodeTranslate::Ruby).to receive(:translate).with(code)
      Morph::CodeTranslate.translate(:ruby, code)
    end

    it "should translate php" do
      expect(Morph::CodeTranslate::PHP).to receive(:translate).with(code)
      Morph::CodeTranslate.translate(:php, code)
    end

    it "should translate python" do
      expect(Morph::CodeTranslate::Python).to receive(:translate).with(code)
      Morph::CodeTranslate.translate(:python, code)
    end
  end

  describe "PHP" do
    describe ".translate" do
      it "should do each step" do
        input, output1, output2 = double, double, double
        expect(Morph::CodeTranslate::PHP).to receive(:add_require).with(input).and_return(output1)
        expect(Morph::CodeTranslate::PHP).to receive(:change_table_in_select).with(output1).and_return(output2)
        expect(Morph::CodeTranslate::PHP.translate(input)).to eq output2
      end
    end

    describe ".add_require" do
      it "should insert require scraperwiki after the opening php tag" do
        expect(Morph::CodeTranslate::PHP.add_require("<?php\nsome code here\nsome more"))
          .to eq "<?php\nrequire 'scraperwiki.php';\nsome code here\nsome more"
      end

      it "shouldn't insert require if it's already there" do
        expect(Morph::CodeTranslate::PHP.add_require("<?php\nrequire 'scraperwiki.php';\nsome code here\nsome more"))
          .to eq "<?php\nrequire 'scraperwiki.php';\nsome code here\nsome more"
      end

      it "shouldn't insert require if it's already there" do
        expect(Morph::CodeTranslate::PHP.add_require("<?php\nrequire \"scraperwiki.php\";\nsome code here\nsome more"))
          .to eq "<?php\nrequire \"scraperwiki.php\";\nsome code here\nsome more"
      end
    end

    describe ".change_table_in_select" do
      it "should change the table name" do
        expect(Morph::CodeTranslate::PHP.change_table_in_select("<?php\nsome code\nprint_r(scraperwiki::select(\"* from swdata\"));\nsome more"))
          .to eq "<?php\nsome code\nprint_r(scraperwiki::select(\"* from data\"));\nsome more"
      end
    end
  end

  describe "Python" do
    it "should do nothing" do
      code = double
      expect(Morph::CodeTranslate::Python.translate(code)).to eq code
    end
  end

  describe "Ruby" do
    describe ".translate" do
      it "should do a series of translations and return the final result" do
        input, output1, output2, output3 = double, double, double, double
        expect(Morph::CodeTranslate::Ruby).to receive(:add_require).with(input).and_return(output1)
        expect(Morph::CodeTranslate::Ruby).to receive(:change_table_in_sqliteexecute_and_select).with(output1).and_return(output2)
        expect(Morph::CodeTranslate::Ruby).to receive(:add_instructions_for_libraries).with(output2).and_return(output3)
        expect(Morph::CodeTranslate::Ruby.translate(input)).to eq output3
      end
    end

    describe ".add_require" do
      it "should do nothing if scraperwiki already required (with single quotes)" do
        expect(Morph::CodeTranslate::Ruby.add_require("require 'scraperwiki'\nsome other code\n"))
          .to eq "require 'scraperwiki'\nsome other code\n"
      end

      it "should do nothing if scraperwiki already required (with double quotes)" do
        expect(Morph::CodeTranslate::Ruby.add_require("require \"scraperwiki\"\nsome other code\n"))
          .to eq "require \"scraperwiki\"\nsome other code\n"
      end

      it "should add the require if it's not there" do
        expect(Morph::CodeTranslate::Ruby.add_require("some code\n"))
          .to eq "require 'scraperwiki'\nsome code\n"
      end

      describe ".change_table_in_sqliteexecute_and_select" do
        it "should replace the table name" do
          expect(Morph::CodeTranslate::Ruby.change_table_in_sqliteexecute_and_select( \
            "ScraperWiki.save_sqlite(swdata)\nScraperWiki.sqliteexecute('select * from swdata', foo, bar)\nScraperWiki.select('select * from swdata; select * from swdata', foo, bar)\n"))
            .to eq "ScraperWiki.save_sqlite(swdata)\nScraperWiki.sqliteexecute('select * from data', foo, bar)\nScraperWiki.select('select * from data; select * from data', foo, bar)\n"
        end

        it "another example" do
          expect(Morph::CodeTranslate::Ruby.change_table_in_sqliteexecute_and_select( \
            "if (ScraperWiki.select(\"* from swdata where `council_reference`='\#{record['council_reference']}'\").empty? rescue true)"))
            .to eq "if (ScraperWiki.select(\"* from data where `council_reference`='\#{record['council_reference']}'\").empty? rescue true)"
        end
      end

      describe ".add_instructions_for_libraries" do
        it "should do nothing if nothing needs to be done" do
          original = <<-EOF
some code
some more code
          EOF
          expect(Morph::CodeTranslate::Ruby.add_instructions_for_libraries(original)).to eq original
        end

        it "should add some help above where a library is required" do
          original = <<-EOF
some code
require 'scrapers/foo'
some more code
          EOF
          translated = <<-EOF
some code
# TODO:
# 1. Fork the ScraperWiki library (if you haven't already) at https://classic.scraperwiki.com/scrapers/foo/
# 2. Add the forked repo as a git submodule in this repo
# 3. Change the line below to something like require File.dirname(__FILE__) + '/foo/scraper'
# 4. Remove these instructions
require 'scrapers/foo'
some more code
          EOF
          expect(Morph::CodeTranslate::Ruby.add_instructions_for_libraries(original)).to eq translated
        end

        it "should also translate where double quotes are used" do
          original = <<-EOF
some code
require "scrapers/foo"
some more code
          EOF
          translated = <<-EOF
some code
# TODO:
# 1. Fork the ScraperWiki library (if you haven't already) at https://classic.scraperwiki.com/scrapers/foo/
# 2. Add the forked repo as a git submodule in this repo
# 3. Change the line below to something like require File.dirname(__FILE__) + '/foo/scraper'
# 4. Remove these instructions
require "scrapers/foo"
some more code
          EOF
          expect(Morph::CodeTranslate::Ruby.add_instructions_for_libraries(original)).to eq translated
        end
      end
    end
  end
end
