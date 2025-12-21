module Cards::ScheduledHelper
  def scheduled_periods
    [
      { key: 'week', label: '1週間' },
      { key: 'month', label: '1ヶ月' },
      { key: 'quarter', label: '3ヶ月' },
      { key: 'later', label: 'それ以降' }
    ]
  end
end
