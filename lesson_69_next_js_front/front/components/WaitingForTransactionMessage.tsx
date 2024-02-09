import React from "react";

type WaitingForTransactionMessageProps = {
  txHash: string;
};

const WaitingForTransactionMessage: React.FunctionComponent<
  WaitingForTransactionMessageProps
> = ({ txHash }) => {
  return (
    <div>
      Waiting for transaction <strong>{txHash}</strong>
    </div>
  );
};

export default WaitingForTransactionMessage;
