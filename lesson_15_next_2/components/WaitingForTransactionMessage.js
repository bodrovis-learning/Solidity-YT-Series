export function WaitingForTransactionMessage({ txHash }) {
  return (
    <div>
      Waiting for transaction <strong>{txHash}</strong>
    </div>
  )
}