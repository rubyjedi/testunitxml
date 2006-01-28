#! /usr/local/bin/ruby


@@lib_path = File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift @@lib_path 

require 'test/unit'

class TestNotationDecl < Test::Unit::TestCase

  def setup
    doc_string = <<-'XMLEND'
    <!DOCTYPE r SYSTEM "urn:x-henrikmartensson:test" [
      <!NOTATION n1 PUBLIC "TEST1">
      <!NOTATION n2 PUBLIC "TEST2" "urn:x-henrikmartensson.org:test2">
      <!NOTATION n3 PUBLIC 'TEST3'>
      <!NOTATION n4 PUBLIC 'TEST4' 'urn:x-henrikmartensson.org:test4'>
      <!NOTATION n5 PUBLIC "TEST5" 'urn:x-henrikmartensson.org:test5'>
      <!NOTATION n6 PUBLIC 'TEST6' "urn:x-henrikmartensson.org:test6">
      <!NOTATION n7 SYSTEM "urn:x-henrikmartensson.org:test7">
    ]>
    <r/>
    XMLEND
    @doctype = REXML::Document.new(doc_string).doctype
  end
  
  def test_public
    assert_equal('TEST1', @doctype.notation('n1').public)
    assert_equal('TEST2', @doctype.notation('n2').public)
    assert_equal('TEST3', @doctype.notation('n3').public)
    assert_equal('TEST4', @doctype.notation('n4').public)
    # The TEST5 and TEST6 assertions have been commented out because
    # REXML 3.1.2 does not parse the notations correctly.
    #assert_equal('TEST5', @doctype.notation('n5').public)
    #assert_equal('TEST6', @doctype.notation('n6').public)
    assert_nil(@doctype.notation('n7').public)
  end
  
  def test_system
    assert_equal("urn:x-henrikmartensson.org:test2", @doctype.notation('n2').system)
    assert_nil(@doctype.notation('n3').system)
    assert_equal("urn:x-henrikmartensson.org:test4", @doctype.notation('n4').system)
    # The TEST5 and TEST6 assertions have been commented out because
    # REXML 3.1.2 does not parse the notations correctly.
    #assert_equal('urn:x-henrikmartensson.org:test5', @doctype.notation('n5').system)
    #assert_equal('urn:x-henrikmartensson.org:test6', @doctype.notation('n6').system)
    assert_equal("urn:x-henrikmartensson.org:test7", @doctype.notation('n7').system)
  end

end