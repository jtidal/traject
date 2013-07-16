require 'test_helper'

require 'traject/solrj_writer'

# WARNING. The SolrJWriter talks to a running Solr server.
#
# set ENV['solrj_writer_url'] to run tests against a real solr server
# OR
# the tests will run against a mock SolrJ server instead.
#
#
# This is pretty limited test right now.
describe "Traject::SolrJWriter" do

  it "raises on missing url" do
    assert_raises(ArgumentError) { Traject::SolrJWriter.new }
    assert_raises(ArgumentError) { Traject::SolrJWriter.new("solrj_writer.url" => nil) }
  end

  describe "with good setup" do
    before do
      @settings = {
        # Use XMLResponseParser just to test, and so it will work
        # with a solr 1.4 test server
        "solrj_writer.parser_class_name" => "XMLResponseParser",
        "solrj_writer.commit_on_close" => "true"
      }

      if ENV["solrj_writer_url"]
        @settings["solrj_writer.url"] = ENV["solrj_writer_url"]
      else
        $stderr.puts "WARNING: Testing SolrJWriter with mock instance"
        @settings["solrj_writer.url"] = "http://example.org/solr"
        @settings["solrj_writer.server_class_name"] = "MockSolrServer"
      end

      @writer = Traject::SolrJWriter.new(@settings)
    end

    it "writes a simple document" do
      @writer.put "title_t" => ["MY TESTING TITLE"], "id" => ["TEST_TEST_TEST_0001"]
      @writer.close


      if @mock
        assert_kind_of org.apache.solr.client.solrj.impl.XMLResponseParser, @mock.parser
        assert_equal @settings["solrj_writer.url"], @mock.url

        assert_equal 1, @mock.docs_added.length
        assert_kind_of SolrInputDocument, @mock.docs_added.first

        assert @mock.committed
        assert @mock.shutted_down

      else
      end
    end



    # I got to see what serialized marc binary does against a real solr server,
    # sorry this is a bit out of place, but this is the class that talks to real
    # solr server right now. This test won't do much unless you have
    # real solr server set up.
    #
    # Not really a good test right now, just manually checking my solr server,
    # using this to make the add reproducible at least. 
    describe "Serialized MARC" do
      it "goes to real solr somehow" do
        record = MARC::Reader.new(support_file_path  "manufacturing_consent.marc").to_a.first

        serialized = record.to_marc # straight binary
        @writer.put "marc_record_t" => [serialized], "id" => ["TEST_TEST_TEST_MARC_BINARY"]
        @writer.close
      end
    end

  end

end

class MockSolrServer
  attr_accessor :docs_added, :url, :committed, :parser, :shutted_down

  def initialize(url)
    @url =  url
    @docs_added = []
  end

  def add(solr_input_document)
    docs_added << solr_input_document
  end

  def commit
    @committed = true
  end

  def setParser(parser)
    @parser = parser
  end

  def shutdown
    @shutted_down = true
  end

end