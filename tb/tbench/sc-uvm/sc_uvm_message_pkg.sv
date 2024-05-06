//-----------------------------------------------------------------------------
// Copyright 2023 Space Cubics, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------
// Space Cubics UVM Message Package
//-----------------------------------------------------------------------------

`ifndef _SC_UVM_MESSAGE_PKG_SV_
`define _SC_UVM_MESSAGE_PKG_SV_

`timescale 1ps/1ps

package sc_uvm_message_pkg;
import uvm_pkg::*;

class sc_report_server extends uvm_default_report_server;

  virtual function string set_show_terminator (bit terminator);
    show_terminator = terminator;
  endfunction

  virtual function string compose_report_message(uvm_report_message report_message, string report_object_name = "");

    string sev_string;
    uvm_severity l_severity;
    uvm_verbosity l_verbosity;
    string filename_line_string;
    string time_str;
    string line_str;
    string context_str;
    string verbosity_str;
    string terminator_str;
    string msg_body_str;
    uvm_report_message_element_container el_container;
    string prefix;
    uvm_report_handler l_report_handler;

    l_severity = report_message.get_severity();
    sev_string = l_severity.name();

    if (report_message.get_filename() != "") begin
      line_str.itoa(report_message.get_line());
      filename_line_string = {report_message.get_filename(), "(", line_str, ") "};
    end

    $swrite(time_str, "%0t", $time);
 
    if (report_message.get_context() != "")
      context_str = {"@@", report_message.get_context()};

    if (show_verbosity) begin
      if ($cast(l_verbosity, report_message.get_verbosity()))
        verbosity_str = l_verbosity.name();
      else
        verbosity_str.itoa(report_message.get_verbosity());
      verbosity_str = {"(", verbosity_str, ")"};
    end

    if (show_terminator)
      terminator_str = {" -",sev_string};

    el_container = report_message.get_element_container();
    if (el_container.size() == 0)
      msg_body_str = report_message.get_message();
    else begin
      prefix = uvm_default_printer.knobs.prefix;
      uvm_default_printer.knobs.prefix = " +";
      msg_body_str = {report_message.get_message(), "\n", el_container.sprint()};
      uvm_default_printer.knobs.prefix = prefix;
    end

    if (report_object_name == "") begin
      l_report_handler = report_message.get_report_handler();
      report_object_name = l_report_handler.get_full_name();
    end

    compose_report_message = {sev_string, verbosity_str, " ", filename_line_string, "@ ", 
      time_str, ": ", report_object_name, context_str,
      " [", report_message.get_id(), "] ", msg_body_str, terminator_str};

  endfunction

endclass

endpackage

`endif
