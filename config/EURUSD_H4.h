/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Awesome_Params_H4 : AOParams {
  Indi_Awesome_Params_H4() : AOParams(indi_awesome_defaults, PERIOD_H4) { shift = 0; }
} indi_awesome_h4;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Awesome_Params_H4 : StgParams {
  // Struct constructor.
  Stg_Awesome_Params_H4() : StgParams(stg_awesome_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)40;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)40;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_awesome_h4;
