import React from "react";

type NetworkErrorMessageProps = {
  message: string;
  dismiss: React.MouseEventHandler<HTMLButtonElement>;
};

const NetworkErrorMessage: React.FunctionComponent<
  NetworkErrorMessageProps
> = ({ message, dismiss }) => {
  return (
    <div>
      {message}
      <button type="button" onClick={dismiss}>
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  );
};

export default NetworkErrorMessage;