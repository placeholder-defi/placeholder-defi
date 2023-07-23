// pages/index.tsx
import WalletList from './WalletList';
import { Page } from 'components/ui/page'
import { Navbar } from 'components/ui/navbar'
const HomePage = () => {
  return (
    <Page>
    <Navbar />
    <div className="px-4 py-4 sm:px-6 lg:px-8 bg-base-300 mb-6">
      <div className="hero my-10">
        <div className="hero-content">
          <div>
            <h1 className="text-5xl font-bold">Dapp user</h1>
            <p className="py-6">this data just for demo walletconnect cloud api</p>
          </div>
        </div>
      </div>
      <WalletList/>
    </div>
  </Page>
   
  );
};

export default HomePage;
