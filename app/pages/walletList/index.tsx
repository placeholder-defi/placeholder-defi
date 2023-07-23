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
            <h1 className="text-5xl font-bold">Price Feeds</h1>
            <p className="py-6">Trade cash-settled derivatives on any of the following price feeds created by the community.</p>
            <label htmlFor="my-modal-3" className="btn btn-primary">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" className="w-6 h-6 mr-2">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Create your own Price Feed
            </label>
          </div>
        </div>
      </div>
      <WalletList/>
    </div>
  </Page>
   
  );
};

export default HomePage;
