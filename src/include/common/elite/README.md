# Elite

## Configuration

### Default

```mermaid
graph TD
    E[EA31337 Elite v3.000] -->|Main| M(Meta MA Cross)
    M --> |Main| S1(RSI)
    M --> |On MA Cross| S2(MA Trend)
```

### Recommended

```mermaid
graph TD
    EA[Elite v3.000] -->|Main| MEquity(Meta Equity)

    MEquity --> |-5-5%| MI(Meta Interval)
    MEquity --> |5-10%| MACSP(MA Cross Sup/Res)
    MEquity --> |-5-10%| DEMA
    MEquity --> |>10%| Ichimoku
    MEquity --> |<10%| Pattern

        MI --> |Main| MSS(Meta Signal Switch)
        MI --> |OnInterval| Alligator

            MSS -->|Main| MRSI(Meta RSI)
            MSS --> |Check| Chaikin
            MSS --> |OnSignal| MMG(Meta Martingale)

                MRSI --> |Neutral| MT(Meta Trend)
                MRSI --> |Peak| MMC(Meta MA Cross)
                MRSI --> |Trend| MOS(Meta Oscillator Switch)

                    MT --> MSpread(Meta Spread)

                        MSpread --> |1pip| DeMarker
                        MSpread --> |1-2ps| DEMA
                        MSpread --> |2-4p| OCS(Oscillator Cross Shift)
                        MSpread --> |>4p| ASI

                MMC --> |Main| MMG(Meta Martingale)
                MMC --> |MA Cross| MAT(MA Trend)

                    MMG --> |Main| MV(Meta Volatility)

                        MV --> |Neutral| Stochastic
                        MV --> |Strong| ATR
                        MV --> |Very strong| DPO


    %% MDouble --> |1st| MEquity(Meta Equity)
    %% MDouble --> |2nd| MSS(Meta Signal Switch)

    %% MM(Meta Margin) --> |>80%| MD(Meta Double)
    %% MM --> |50-80%| MOL(Meta Order Limit)
    %% MM --> |20-50%| AMA
    %% MM --> |<20%| NA1(n/a)

    %%     MD --> |Strat1| MP(Meta Pivot)
    %%     MD --> |Strat2| MMC(Meta MA Cross)

    %%     MOL --> |Strat| MAB(MA Breakout)

    %%         MP --> |S1/R1| MCS(MA Cross Shift)
    %%         MP --> |S2/R2| MACD
    %%         MP --> |S3/R3| MC(Meta Conditions)
    %%         MP --> |S4/R4| MAT(MA Trend)

    %%             MRev(Meta Reverse) --> |S1| MC(Meta Conditions)

    %%                 MC --> |C1-AtPeak| Gator
    %%                 MC --> |C2-InPivot| Awesome
    %%                 %%% MC --> |C3| NA2(n/a)

    %% MOS --> |Type| ATR
    %% MOS --> |Down| MMC(Meta MA Cross)
    %% MOS --> |Up| MMG(Meta Martingale)
```
