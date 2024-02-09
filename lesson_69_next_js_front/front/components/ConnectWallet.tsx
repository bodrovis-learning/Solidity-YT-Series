import React from "react";
import NetworkErrorMessage from "./NetworkErrorMessage";

type ConnectWalletProps = {
  connectWallet: React.MouseEventHandler<HTMLButtonElement>;
  dismiss: React.MouseEventHandler<HTMLButtonElement>;
  networkError: string | undefined;
};

const ConnectWallet: React.FunctionComponent<ConnectWalletProps> = ({
  connectWallet,
  networkError,
  dismiss,
}) => {
  return (
    <>
      <div>
        {networkError && (
          <NetworkErrorMessage message={networkError} dismiss={dismiss} />
        )}
      </div>

      <p>Please connect your account...</p>
      <button type="button" onClick={connectWallet}>
        Connect wallet
      </button>
    </>
  );
};

export default ConnectWallet;