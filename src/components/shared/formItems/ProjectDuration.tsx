import { Form, Space, Switch } from 'antd'
import { useEffect, useState } from 'react'

import InputAccessoryButton from '../InputAccessoryButton'
import FormattedNumberInput from '../inputs/FormattedNumberInput'
import { FormItemExt } from './formItemExt'

export default function ProjectDuration({
  name,
  formItemProps,
  value,
  isRecurring,
  hideLabel,
  onToggleRecurring,
  onValueChange,
}: {
  value: string | undefined
  isRecurring: boolean | undefined
  onToggleRecurring: VoidFunction
  onValueChange: (val?: string) => void
} & FormItemExt) {
  const [showDurationInput, setShowDurationInput] = useState<boolean>()

  useEffect(() => {
    if (value && value !== '0') setShowDurationInput(true)
  })

  return (
    <div>
      <Space direction="vertical">
        <div>
          <Space>
            <Switch
              checked={showDurationInput}
              onChange={checked => {
                setShowDurationInput(checked)
                onValueChange(checked ? '30' : '0')
              }}
            />
            <label>Set a funding cycle duration</label>
          </Space>
        </div>

        <Form.Item
          extra="How long one funding cycle will last. Changes to upcoming funding cycles will only take effect once the current cycle has ended."
          name={name}
          label={hideLabel ? undefined : 'Funding period'}
          {...formItemProps}
          style={{ display: showDurationInput ? 'block' : 'none' }}
        >
          <FormattedNumberInput
            placeholder="30"
            value={value}
            suffix="days"
            onChange={onValueChange}
            min={1}
            accessory={
              <InputAccessoryButton
                content={isRecurring ? 'recurring' : 'one-time'}
                withArrow={true}
                onClick={onToggleRecurring}
              />
            }
          />
        </Form.Item>
      </Space>
    </div>
  )
}
