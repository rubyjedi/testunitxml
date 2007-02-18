#!/usr/bin/env ruby
#
#  Created by Henrik Mårtensson on 2007-02-17.
#  Copyright (c) 2007. All rights reserved.
@@lib_path = File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift @@lib_path 

require "test/unit"

require "test/unit/xml"

class TestTestUnitXml2 < Test::Unit::TestCase
  
  # <?xml version="1.0" encoding="utf-8"?>
  def test_soap_message
    expected = <<-end_xml
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <soap:Body>
      <TestThing><SomeStringValue>soaptastic</SomeStringValue></TestThing>
      </soap:Body>
      </soap:Envelope>
    end_xml
    actual = <<-end_xml
      <soap:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <soap:Body>
      <TestThing/>
      </soap:Body>
      </soap:Envelope>
    end_xml
    assert_xml_not_equal expected, actual, "Documents expected not to be equal, but were equal."
  end
  

end