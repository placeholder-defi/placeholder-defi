import { createChart, CrosshairMode } from "lightweight-charts";
import { FC, useRef, useEffect } from "react";

let pass = false;

export function ChartIndex({ width, height }) {
  const chartRef = useRef(null);

  useEffect(() => {
    if (pass) return;

    const chart = createChart(chartRef.current || "", {
      width: width,
      height: height,
      layout: {
        backgroundColor: '#000000',
        textColor: 'rgba(255, 255, 255, 0.9)',
      },
      grid: {
        vertLines: {
          color: 'rgba(197, 203, 206, 0.5)',
        },
        horzLines: {
          color: 'rgba(197, 203, 206, 0.5)',
        },
      },
      crosshair: {
        mode: CrosshairMode.Normal,
      },
      rightPriceScale: {
        borderColor: 'rgba(197, 203, 206, 0.8)',
      },
      timeScale: {
        borderColor: 'rgba(197, 203, 206, 0.8)',
      },
    });


    var candleSeries = chart.addCandlestickSeries({
      upColor: 'rgba(255, 144, 0, 1)',
      downColor: '#000',
      borderDownColor: 'rgba(255, 144, 0, 1)',
      borderUpColor: 'rgba(255, 144, 0, 1)',
      wickDownColor: 'rgba(255, 144, 0, 1)',
      wickUpColor: 'rgba(255, 144, 0, 1)',
    });
    candleSeries.setData([]);
// Fetch the data from the API
    //  await fetch(apiUrl)
    //   .then(response => response.json())
    //   .then(data => {
    //   // Format the data to match the candlestick format
    //   const formattedData = data.map(item => {
    //   return {
    //   x: item[0], // Timestamp
    //   y: [item[1], item[2], item[3], item[4]] // OHLC values
    //   };
    //   candleSeries.setData(formattedData);
    //   });
   
      candleSeries.setData(formattedData);
    pass = true;
  }, []);

  return (
    <div ref={chartRef} />
  );
};

export default ChartIndex;