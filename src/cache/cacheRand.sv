///////////////////////////////////////////
// cacheLRU.sv
//
// Written: Rose Thompson ross1728@gmail.com
// Created: 20 July 2021
// Modified: 20 January 2023
//
// Purpose: Implements Pseudo LRU. Tested for Powers of 2.
//
// Documentation: RISC-V System on Chip Design Chapter 7 (Figures 7.8 and 7.15 to 7.18)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module cacheRand
  #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128) (
  input  logic                clk, 
  input  logic                reset,
  input  logic                FlushStage,
  input  logic                CacheEn,         // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [NUMWAYS-1:0]  HitWay,          // Which way is valid and matches PAdr's tag
  input  logic [NUMWAYS-1:0]  ValidWay,        // Which ways for a particular set are valid, ignores tag
  input  logic [SETLEN-1:0]   CacheSetData,    // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   CacheSetTag,     // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   PAdr,            // Physical address 
  input  logic                LRUWriteEn,      // Update the LRU state
  input  logic                SetValid,        // Set the dirty bit in the selected way and set
  input  logic                ClearValid,      // Clear the dirty bit in the selected way and set
  input  logic                InvalidateCache, // Clear all valid bits
  output logic [NUMWAYS-1:0]  VictimWay        // LRU selects a victim to evict
);

  localparam                           LOGNUMWAYS = $clog2(NUMWAYS);

  logic [LOGNUMWAYS-1:0]               HitWayEncoded, Way;
  logic [NUMWAYS-2:0]                  WayExpanded;
  logic                                AllValid;
  
 
 logic [LOGNUMWAYS+1:0] randVal;
  LFSR7 #(LOGNUMWAYS) rp(clk, reset, FlushStage, LRUWriteEn, randVal);

	
 

  logic [NUMWAYS-1:0] FirstZero;
  logic [LOGNUMWAYS-1:0] FirstZeroWay;
  logic [LOGNUMWAYS-1:0] VictimWayEnc;

  binencoder #(NUMWAYS) hitwayencoder(HitWay, HitWayEncoded);

  assign AllValid = &ValidWay;   
  
  priorityonehot #(NUMWAYS) FirstZeroEncoder(~ValidWay, FirstZero);
  binencoder #(NUMWAYS) FirstZeroWayEncoder(FirstZero, FirstZeroWay);
  mux2 #(LOGNUMWAYS) VictimMux(FirstZeroWay, randVal[LOGNUMWAYS-1:0], AllValid, VictimWayEnc);
  decoder #(LOGNUMWAYS) decoder (VictimWayEnc, VictimWay);

  // LRU storage must be reset for modelsim to run. However the reset value does not actually matter in practice.
  // This is a two port memory.
  // Every cycle must read from CacheSetData and each load/store must write the new LRU.

endmodule

module LFSR7 #(parameter LOGNUMWAYS) (input logic clk, reset, FlushStage, LRUWriteEn,
	     output logic [LOGNUMWAYS+1:0] Current);
	
	logic en;
	logic [LOGNUMWAYS+1:0] val; 
	logic [LOGNUMWAYS+1:0] Curr;
	assign en = ~FlushStage & LRUWriteEn;
	assign val[0] = 1'b1;  // assigns first bit to always be 1
	assign val[LOGNUMWAYS+1:1] = '0; //cuts off 0's before the 1 in the first bit
	logic ShiftIn;	
	assign Current = Curr;

	if(LOGNUMWAYS == 1)begin
		assign ShiftIn =Curr[0] ^ Curr[2];
	end
	else if(LOGNUMWAYS == 2)begin
		assign ShiftIn = Curr[0] ^ Curr[3];
	end
	else if(LOGNUMWAYS == 3)begin
		assign ShiftIn = Curr[0] ^ Curr[2] ^ Curr[3] ^ Curr[4];
	end
	else if(LOGNUMWAYS == 4)begin
		assign ShiftIn = Curr[0] ^ Curr[1] ^ Curr[2] ^ Curr[4] ^ Curr[5];
	end
	else if(LOGNUMWAYS == 5)begin
		assign ShiftIn = Curr[0] ^ Curr[3] ^ Curr[5] ^ Curr[6];
	end
	else if(LOGNUMWAYS == 6) begin
		assign ShiftIn = Curr[1] ^ Curr[2] ^ Curr[5] ^ Curr[7];
	end	
	else if (LOGNUMWAYS==7) begin

		assign ShiftIn = Curr[2] ^ Curr[3] ^ Curr[4] ^ Curr[5] ^ Curr[6] ^ Curr[8];
	end


	flopenl #(LOGNUMWAYS+2) fl0(clk, reset, en, {ShiftIn, Curr[LOGNUMWAYS+1:1]}, val, Curr);
	
endmodule

