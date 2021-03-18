import { Input } from 'antd'
import { CaretDownOutlined } from '@ant-design/icons'
import { BudgetCurrency } from 'models/budget-currency'
import React from 'react'
import { budgetCurrencyName } from 'utils/budgetCurrency'

import InputAccessoryButton from './InputAccessoryButton'

export default function BudgetTargetInput({
  currency,
  value,
  onValueChange,
  onCurrencyChange,
  disabled,
}: {
  currency?: BudgetCurrency
  value?: string
  onValueChange: (value: string) => void
  onCurrencyChange: (currency: BudgetCurrency) => void
  disabled?: boolean
}) {
  if (currency === undefined) return null

  const budgetCurrencySelector = (
    <InputAccessoryButton
      onClick={() => onCurrencyChange(currency)}
      content={
        <span>
          {budgetCurrencyName(currency)}{' '}
          <CaretDownOutlined
            style={{ fontSize: 10, marginLeft: -4, marginRight: -4 }}
          />
        </span>
      }
      placement="suffix"
    />
  )

  return (
    <Input
      value={value}
      placeholder="0"
      type="number"
      disabled={disabled}
      suffix={budgetCurrencySelector}
      onChange={e => onValueChange(e.target.value)}
    />
  )
}