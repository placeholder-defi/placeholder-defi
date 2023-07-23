// pages/WalletList.tsx
import { useEffect, useState } from 'react';
import axios from 'axios';
import { Page } from 'components/ui/page'
import { XYPlot, VerticalBarSeries, HorizontalBarSeries, XAxis, YAxis } from 'react-vis';

interface Wallet {
  id: string;
  name: string;
  slug: string;
  description: string;
  homepage: string;
  chains: string[];
  versions: string[];
  sdks: string[];
  app_type: string;
}

const WalletList = () => {
  const [wallets, setWallets] = useState<Wallet[]>([]);
  const [selectedAppType, setSelectedAppType] = useState<string>(''); // State for selected app type

  useEffect(() => {
    // Replace 'YOUR_PROJECT_ID' with your actual project ID
    const projectId = '7456c703c74d537c68c7168607faeb5b';
    const apiUrl = `https://explorer-api.walletconnect.com/v3/wallets?projectId=${projectId}&entries=5&page=1`;

    axios.get(apiUrl)
    .then((response) => {
      const walletData = response.data.listings;
      const walletArray: Wallet[] = Object.values(walletData);
      setWallets(walletArray);
    })
    .catch((error) => {
      console.error('Error fetching data:', error);
    });
  }, []);


  // Function to get the count of wallets per app type
  const getWalletCountsByAppType = () => {
    const appTypes: { [key: string]: number } = {};
    wallets.forEach((wallet) => {
      if (appTypes.hasOwnProperty(wallet.app_type)) {
        appTypes[wallet.app_type]++;
      } else {
        appTypes[wallet.app_type] = 1;
      }
    });
    return appTypes;
  };

  // Function to filter wallets based on the selected app type
  const filteredWallets = selectedAppType
    ? wallets.filter((wallet) => wallet.app_type === selectedAppType)
    : wallets;

  // Function to convert the wallet counts into data format for the bar chart
  const getBarChartData = () => {
    const walletCounts = getWalletCountsByAppType();
    const labels = Object.keys(walletCounts);
    const data = Object.values(walletCounts);
    return {
      labels: labels,
      datasets: [
        {
          label: 'Number of Wallets',
          data: data,
          backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#8B5F65', '#4BC0C0'],
        },
      ],
    };
  };

  // // Function to convert the wallet counts into data format for the pie chart
  // const getPieChartData = () => {
  //   const walletCounts = getWalletCountsByAppType();
  //   const labels = Object.keys(walletCounts);
  //   const data = Object.values(walletCounts);
  //   return {
  //     labels: labels,
  //     datasets: [
  //       {
  //         data: data,
  //         backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#8B5F65', '#4BC0C0'],
  //       },
  //     ],
  //   };
  // };
  
  // Function to convert the wallet counts into data format for the horizontal bar chart
  const getHorizontalBarChartData = () => {
    const walletCounts = getWalletCountsByAppType();
    const data = Object.entries(walletCounts).map(([label, count]) => ({
      x: count,
      y: label,
    }));
    return data;
  };

  const barChartData = getBarChartData();
  // const pieChartData = getPieChartData();
  // const horizontalBarChartData = getHorizontalBarChartData();


  return (
    <div>
      <h1>Wallet List</h1>
        {/* Dropdown menu to filter data based on app type */}
      <select
        value={selectedAppType}
        onChange={(e) => setSelectedAppType(e.target.value)}
        style={{ marginBottom: '20px' }}
      >
        <option value="">All App Types</option>
        {Object.keys(getWalletCountsByAppType()).map((appType) => (
          <option key={appType} value={appType}>
            {appType}
          </option>
        ))}
      </select>
      <div className="overflow-x-auto max-w-full scrollbar-thin scrollbar-thumb-accent rounded-lg shadow-lg">
        <table  className="table w-full" >
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Slug</th>
              <th>Description</th>
              <th>Homepage</th>
              <th>Chains</th>
              <th>Versions</th>
              <th>SDks</th>
              <th>App Type</th>
            </tr>
          </thead>
          <tbody>
            {wallets.map((wallet) => (
              <tr key={wallet.id}>
                    <td>
                  <div className="flex items-center">{wallet.id}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.name}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.slug}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.description}</div>
                </td>
                <td>
                  <div className="flex items-center">
                    <a href={wallet.homepage} target="_blank" rel="noopener noreferrer">
                      Homepage
                    </a>
                  </div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.chains.join(', ')}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.versions.join(', ')}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.sdks.join(', ')}</div>
                </td>
                <td>
                  <div className="flex items-center">{wallet.app_type}</div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
         {/* Bar Chart
         <div style={{ width: '30%', maxWidth: '400px' }}>
          <h2>Bar Chart - Number of Wallets per App Type</h2>
          <XYPlot height={300} width={300} xType="ordinal">
            <VerticalBarSeries data={barChartData} />
            <XAxis />
            <YAxis />
          </XYPlot>
        </div>      */}
    </div>
     
  );
};

export default WalletList;