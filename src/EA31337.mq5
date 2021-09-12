//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Includes.
#include "include/includes.h"

// EA properties.
#ifdef __property__
#property copyright ea_copy
#property description ea_name
#property description ea_desc
#property icon "resources/favicon.ico"
#property link ea_link
#property version ea_version
#endif

// Global variables.
EA *ea;

/* EA event handler functions */

/**
 * Initialization function of the expert.
 */
int OnInit() {
  bool _initiated = true;
  PrintFormat("%s v%s (%s) initializing...", ea_name, ea_version, ea_link);
  _initiated &= InitEA();
  _initiated &= InitStrategies();
  if (GetLastError() > 0) {
    ea.GetLogger().Error("Error during initializing!", __FUNCTION_LINE__, Terminal::GetLastErrorText());
  }
  if (EA_DisplayDetailsOnChart) {
    DisplayStartupInfo(true);
  }
  ea.GetLogger().Flush();
  Chart::WindowRedraw();
  if (!_initiated) {
    ea.GetState().Enable(false);
  }
  return (_initiated ? INIT_SUCCEEDED : INIT_FAILED);
}

/**
 * Deinitialization function of the expert.
 */
void OnDeinit(const int reason) { DeinitVars(); }

/**
 * "Tick" event handler function (EA only).
 *
 * Invoked when a new tick for a symbol is received, to the chart of which the Expert Advisor is attached.
 */
void OnTick() {
  EAProcessResult _result = ea.ProcessTick();
  if (_result.stg_processed || ea.GetState().new_periods > 0) {
    if (EA_DisplayDetailsOnChart && (Terminal::IsVisualMode() || Terminal::IsRealtime())) {
      string _text = StringFormat("%s v%s by %s (%s)\n", ea_name, ea_version, ea_author, ea_link);
      _text += SerializerConverter::FromObject(ea, SERIALIZER_FLAG_INCLUDE_DYNAMIC).ToString<SerializerJson>();
      Comment(_text);
    }
  }
}

#ifdef __MQL5__
/**
 * "Trade" event handler function (MQL5 only).
 *
 * Invoked when a trade operation is completed on a trade server.
 */
void OnTrade() {}

/**
 * "OnTradeTransaction" event handler function (MQL5 only).
 *
 * Invoked when performing some definite actions on a trade account, its state changes.
 */
void OnTradeTransaction(const MqlTradeTransaction &trans,  // Trade transaction structure.
                        const MqlTradeRequest &request,    // Request structure.
                        const MqlTradeResult &result       // Result structure.
) {}

/**
 * "Timer" event handler function (MQL5 only).
 *
 * Invoked periodically generated by the EA that has activated the timer by the EventSetTimer function.
 * Usually, this function is called by OnInit.
 */
void OnTimer() {}

/**
 * "TesterInit" event handler function (MQL5 only).
 *
 * The start of optimization in the strategy tester before the first optimization pass.
 *
 * Invoked with the start of optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void TesterInit() {}

/**
 * "OnTester" event handler function.
 *
 * Invoked after a history testing of an Expert Advisor on the chosen interval is over.
 * It is called right before the call of OnDeinit().
 *
 * Returns calculated value that is used as the Custom max criterion
 * in the genetic optimization of input parameters.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
// double OnTester() { return 1.0; }

/**
 * "OnTesterPass" event handler function (MQL5 only).
 *
 * Invoked when a frame is received during Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterPass() {}

/**
 * "OnTesterDeinit" event handler function (MQL5 only).
 *
 * Invoked after the end of Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterDeinit() {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked on Depth of Market changes.
 * To pre-subscribe use the MarketBookAdd() function.
 * In order to unsubscribe for a particular symbol, call MarketBookRelease().
 */
void OnBookEvent(const string &symbol) {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked by the client terminal when a user is working with a chart.
 */
void OnChartEvent(const int id,          // Event ID.
                  const long &lparam,    // Parameter of type long event.
                  const double &dparam,  // Parameter of type double event.
                  const string &sparam   // Parameter of type string events.
) {}

// @todo: OnTradeTransaction (https://www.mql5.com/en/docs/basis/function/events).
#endif  // end: __MQL5__

/* Custom EA functions */

/**
 * Display info on the chart.
 */
bool DisplayStartupInfo(bool _startup = false, string sep = "\n") {
  string _output = "";
  ResetLastError();
  if (ea.GetState().IsOptimizationMode() || (ea.GetState().IsTestingMode() && !ea.GetState().IsVisualMode())) {
    // Ignore chart updates when optimizing or testing in non-visual mode.
    return false;
  }
  _output += "ACCOUNT: " + ea.Account().ToString() + sep;
  _output += "EA: " + ea.ToString() + sep;
  _output += "MARKET: " + ea.Market().ToString() + sep;
  _output += "SYMBOL: " + ea.SymbolInfo().ToString() + sep;
  _output += "TERMINAL: " + ea.GetTerminal().ToString() + sep;
#ifdef __advanced__
  // Print enabled strategies info.
  for (DictStructIterator<long, Ref<Strategy>> _siter = ea.GetStrategies().Begin(); _siter.IsValid(); ++_siter) {
    Strategy *_strat = _siter.Value().Ptr();
    string _sname =
        _strat.GetName();  // + "@" + ChartTf::TfToString(_strat.GetTf().Get<ENUM_TIMEFRAMES>(CHART_PARAM_TF));
    _output += StringFormat("Strategy: %s: %s\n", _sname,
                            SerializerConverter::FromObject(_strat, SERIALIZER_FLAG_INCLUDE_DYNAMIC)
                                .ToString<SerializerJson>(SERIALIZER_JSON_NO_WHITESPACES));
  }
#endif
  if (_startup) {
    if (ea.GetState().IsTradeAllowed()) {
      if (!Terminal::HasError()) {
        _output += sep + "Trading is allowed, waiting for new bars...";
      } else {
        _output += sep + "Trading is allowed, but there is some issue...";
        _output += sep + Terminal::GetLastErrorText();
        ea.GetLogger().AddLastError(__FUNCTION_LINE__);
      }
    } else if (Terminal::IsRealtime()) {
      _output += sep + StringFormat(
                           "Error %d: Trading is not allowed for this symbol, please enable automated trading or check "
                           "the settings!",
                           __LINE__);
    } else {
      _output += sep + "Waiting for new bars...";
    }
  }
  Comment(_output);
  return !Terminal::HasError();
}

/**
 * Init EA.
 */
bool InitEA() {
  bool _initiated = ea_auth;
  EAParams ea_params(__FILE__, VerboseLevel);
  // ea_params.SetChartInfoFreq(EA_DisplayDetailsOnChart ? 2 : 0);
  // EA params.
  ea_params.SetDetails(ea_name, ea_desc, ea_version, StringFormat("%s (%s)", ea_author, ea_link));
  // Risk params.
  ea_params.Set(STRUCT_ENUM(EAParams, EA_PARAM_PROP_RISK_MARGIN_MAX), EA_Risk_MarginMax);
  ea_params.SetFlag(EA_PARAM_FLAG_LOTSIZE_AUTO, EA_LotSize <= 0);
  // Init instance.
  ea = new EA(ea_params);
  ea.Set(TRADE_PARAM_RISK_MARGIN, EA_Risk_MarginMax);
  if (!ea.GetState().IsTradeAllowed()) {
    ea.GetLogger().Error(
        "Trading is not allowed for this symbol, please enable automated trading or check the settings!",
        __FUNCTION_LINE__);
    _initiated &= false;
  }
#ifdef __advanced__
  if (_initiated) {
    TaskEntry _task1 = GetTask(EA_Task1_If, EA_Task1_Then);
    TaskEntry _task2 = GetTask(EA_Task2_If, EA_Task2_Then);
    _initiated &= ea.TaskAdd(_task1);
    _initiated &= ea.TaskAdd(_task2);
  }
#endif
  return _initiated;
}

/**
 * Init strategies.
 */
bool InitStrategies() {
  bool _res = ea_exists;
  int _magic_step = FINAL_ENUM_TIMEFRAMES_INDEX;
  long _magic_no = EA_MagicNumber;
  ResetLastError();
  // Initialize strategies per timeframe.
  EAStrategyAdd(Strategy_M1, 1 << M1);
  EAStrategyAdd(Strategy_M5, 1 << M5);
  EAStrategyAdd(Strategy_M15, 1 << M15);
  EAStrategyAdd(Strategy_M30, 1 << M30);
  EAStrategyAdd(Strategy_H1, 1 << H1);
  EAStrategyAdd(Strategy_H2, 1 << H2);
  EAStrategyAdd(Strategy_H3, 1 << H3);
  EAStrategyAdd(Strategy_H4, 1 << H4);
  // Update lot size.
  ea.Set(STRAT_PARAM_LS, EA_LotSize);
#ifdef __advanced__
  ea.Set(STRAT_PARAM_SOFM, EA_SignalOpenFilterMethod);
  ea.Set(STRAT_PARAM_SCF, EA_SignalCloseFilter);
  ea.Set(STRAT_PARAM_SOFT, EA_SignalOpenFilterTime);
  ea.Set(STRAT_PARAM_TFM, EA_TickFilterMethod);
  ea.Set(STRUCT_ENUM(EAParams, EA_PARAM_PROP_SIGNAL_FILTER), EA_SignalOpenStrategyFilter);
#ifdef __rider__
  // Disables strategy defined order closures for Rider.
  ea.Set(STRAT_PARAM_OCL, 0);
  ea.Set(STRAT_PARAM_OCP, 0);
  ea.Set(STRAT_PARAM_OCT, 0);
  // Init price stop methods for all timeframes.
  EAStrategyAddStops(NULL, EA_Stops_Strat, EA_Stops_Tf);
#else
  ea.Set(STRAT_PARAM_OCL, EA_OrderCloseLoss);
  ea.Set(STRAT_PARAM_OCP, EA_OrderCloseProfit);
  ea.Set(STRAT_PARAM_OCT, EA_OrderCloseTime);
  // Init price stop methods for each timeframe.
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M1), EA_Stops_M1, PERIOD_M1);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M5), EA_Stops_M5, PERIOD_M5);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M15), EA_Stops_M15, PERIOD_M15);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M30), EA_Stops_M30, PERIOD_M30);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H1), EA_Stops_H1, PERIOD_H1);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H2), EA_Stops_H2, PERIOD_H2);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H3), EA_Stops_H3, PERIOD_H3);
  _res &= EAStrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H4), EA_Stops_H4, PERIOD_H4);
#endif                                                    // __rider__
#endif                                                    // __advanced__
  _res &= GetLastError() == 0 || GetLastError() == 5053;  // @fixme: error 5053?
  ResetLastError();
  return _res && ea_configured;
}

/**
 * Adds strategy to the given timeframe.
 */
bool EAStrategyAdd(ENUM_STRATEGY _stg, int _tfs) {
  unsigned int _magic_no = EA_MagicNumber + _stg * FINAL_ENUM_TIMEFRAMES_INDEX;
  switch (_stg) {
    case STRAT_AC:
      return ea.StrategyAdd<Stg_AC>(_tfs, _magic_no, _stg);
    case STRAT_AD:
      return ea.StrategyAdd<Stg_AD>(_tfs, _magic_no, _stg);
    case STRAT_ADX:
      return ea.StrategyAdd<Stg_ADX>(_tfs, _magic_no, _stg);
    case STRAT_ATR:
      return ea.StrategyAdd<Stg_ATR>(_tfs, _magic_no, _stg);
    case STRAT_ALLIGATOR:
      return ea.StrategyAdd<Stg_Alligator>(_tfs, _magic_no, _stg);
    case STRAT_AWESOME:
      return ea.StrategyAdd<Stg_Awesome>(_tfs, _magic_no, _stg);
    case STRAT_BWMFI:
      return ea.StrategyAdd<Stg_BWMFI>(_tfs, _magic_no, _stg);
    case STRAT_BANDS:
      return ea.StrategyAdd<Stg_Bands>(_tfs, _magic_no, _stg);
    case STRAT_BEARS_POWER:
      return ea.StrategyAdd<Stg_BearsPower>(_tfs, _magic_no, _stg);
    case STRAT_BULLS_POWER:
      return ea.StrategyAdd<Stg_BullsPower>(_tfs, _magic_no, _stg);
    case STRAT_CCI:
      return ea.StrategyAdd<Stg_CCI>(_tfs, _magic_no, _stg);
    case STRAT_DEMA:
      return ea.StrategyAdd<Stg_DEMA>(_tfs, _magic_no, _stg);
    case STRAT_DEMARKER:
      return ea.StrategyAdd<Stg_DeMarker>(_tfs, _magic_no, _stg);
    case STRAT_ENVELOPES:
      return ea.StrategyAdd<Stg_Envelopes>(_tfs, _magic_no, _stg);
    case STRAT_EWO:
      return ea.StrategyAdd<Stg_ElliottWave>(_tfs, _magic_no, _stg);
    case STRAT_FORCE:
      return ea.StrategyAdd<Stg_Force>(_tfs, _magic_no, _stg);
    case STRAT_FRACTALS:
      return ea.StrategyAdd<Stg_Fractals>(_tfs, _magic_no, _stg);
    case STRAT_GATOR:
      return ea.StrategyAdd<Stg_Gator>(_tfs, _magic_no, _stg);
    case STRAT_HEIKEN_ASHI:
      return ea.StrategyAdd<Stg_HeikenAshi>(_tfs, _magic_no, _stg);
    case STRAT_ICHIMOKU:
      return ea.StrategyAdd<Stg_Ichimoku>(_tfs, _magic_no, _stg);
    case STRAT_MA:
      return ea.StrategyAdd<Stg_MA>(_tfs, _magic_no, _stg);
    case STRAT_MACD:
      return ea.StrategyAdd<Stg_MACD>(_tfs, _magic_no, _stg);
    case STRAT_MFI:
      return ea.StrategyAdd<Stg_MFI>(_tfs, _magic_no, _stg);
    case STRAT_MOMENTUM:
      return ea.StrategyAdd<Stg_Momentum>(_tfs, _magic_no, _stg);
    case STRAT_OBV:
      return ea.StrategyAdd<Stg_OBV>(_tfs, _magic_no, _stg);
    case STRAT_OSMA:
      return ea.StrategyAdd<Stg_OsMA>(_tfs, _magic_no, _stg);
    case STRAT_PATTERN:
      return ea.StrategyAdd<Stg_Pattern>(_tfs, _magic_no, _stg);
    case STRAT_RSI:
      return ea.StrategyAdd<Stg_RSI>(_tfs, _magic_no, _stg);
    case STRAT_RVI:
      return ea.StrategyAdd<Stg_RVI>(_tfs, _magic_no, _stg);
    case STRAT_SAR:
      return ea.StrategyAdd<Stg_SAR>(_tfs, _magic_no, _stg);
    case STRAT_SAWA:
      return ea.StrategyAdd<Stg_SAWA>(_tfs, _magic_no, _stg);
    case STRAT_STDDEV:
      return ea.StrategyAdd<Stg_StdDev>(_tfs, _magic_no, _stg);
    case STRAT_STOCHASTIC:
      return ea.StrategyAdd<Stg_Stochastic>(_tfs, _magic_no, _stg);
    case STRAT_SVE_BB:
      return ea.StrategyAdd<Stg_SVE_Bollinger_Bands>(_tfs, _magic_no, _stg);
    case STRAT_TMAT_SVEBB:
      return ea.StrategyAdd<Stg_TMAT_SVEBB>(_tfs, _magic_no, _stg);
    case STRAT_TMA_TRUE:
      return ea.StrategyAdd<Stg_TMA_True>(_tfs, _magic_no, _stg);
    case STRAT_WPR:
      return ea.StrategyAdd<Stg_WPR>(_tfs, _magic_no, _stg);
    case STRAT_ZIGZAG:
      return ea.StrategyAdd<Stg_ZigZag>(_tfs, _magic_no, _stg);
  }
  return _stg == STRAT_NONE;
}

/**
 * Adds strategy stops.
 */
bool EAStrategyAddStops(Strategy *_strat = NULL, ENUM_STRATEGY _enum_stg_stops = STRAT_NONE, ENUM_TIMEFRAMES _tf = 0) {
  bool _result = true;
  if (_enum_stg_stops == STRAT_NONE) {
    return _result;
  }
  Strategy *_strat_stops = ea.GetStrategyViaProp2<int, int>(STRAT_PARAM_TYPE, _enum_stg_stops, STRAT_PARAM_TF, _tf);
  if (!_strat_stops) {
    _result &= EAStrategyAdd(_enum_stg_stops, 1 << ChartTf::TfToIndex(_tf));
    _strat_stops = ea.GetStrategyViaProp2<int, int>(STRAT_PARAM_TYPE, _enum_stg_stops, STRAT_PARAM_TF, _tf);
    if (_strat_stops) {
      _strat_stops.Enabled(false);
    }
  }
  if (_strat_stops) {
    if (_strat != NULL && _tf > 0) {
      _strat.SetStops(_strat_stops, _strat_stops);
    } else {
      for (DictStructIterator<long, Ref<Strategy>> iter = ea.GetStrategies().Begin(); iter.IsValid(); ++iter) {
        Strategy *_strat_ref = iter.Value().Ptr();
        if (_strat_ref.IsEnabled()) {
          _strat_ref.SetStops(_strat_stops, _strat_stops);
        }
      }
    }
  }
  return _result;
}

/**
 * Deinitialize global class variables.
 */
void DeinitVars() { Object::Delete(ea); }
