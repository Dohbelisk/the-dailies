import { Link } from 'react-router-dom'
import { Puzzle, ArrowLeft, Mail, MessageSquare, CreditCard, Bug, HelpCircle, Smartphone } from 'lucide-react'

export default function Support() {
  const contactEmail = 'support@dohblisk.com'

  const faqs = [
    {
      question: 'How do I restore my premium subscription?',
      answer: 'Go to Settings in the app and tap "Restore Subscription". Make sure you\'re signed into the same Google Play or App Store account that you used to purchase the subscription.'
    },
    {
      question: 'How do I cancel my subscription?',
      answer: 'Subscriptions are managed through your device\'s app store. On Android: Google Play Store → Subscriptions → The Dailies → Cancel. On iOS: Settings → Apple ID → Subscriptions → The Dailies → Cancel.'
    },
    {
      question: 'What happens when my free trial ends?',
      answer: 'If you don\'t cancel before the trial ends, you\'ll be automatically charged $1.99/month. You can cancel anytime before the trial ends to avoid being charged.'
    },
    {
      question: 'How do I earn tokens for archive puzzles?',
      answer: 'Free users receive 1 token daily. You can also watch rewarded video ads to earn 5 tokens. Premium subscribers have unlimited archive access without needing tokens.'
    },
    {
      question: 'Why am I seeing ads?',
      answer: 'The free version of The Dailies includes ads to support development. Subscribe to Premium for an ad-free experience.'
    },
    {
      question: 'How do hints work?',
      answer: 'Free users get 3 hints per day, which reset at midnight. You can watch rewarded ads for 3 additional hints. Premium subscribers have unlimited hints.'
    },
    {
      question: 'Is my progress saved?',
      answer: 'Yes, your game progress, scores, and statistics are saved locally on your device. Creating an account allows you to sync progress and compete with friends.'
    },
    {
      question: 'How do I delete my account?',
      answer: 'Contact us at support@dohblisk.com with your account email and we\'ll process your deletion request within 30 days.'
    }
  ]

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link to="/" className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary-600 rounded-xl flex items-center justify-center">
              <Puzzle className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">The Dailies</h1>
              <p className="text-xs text-gray-500 dark:text-gray-400">Support</p>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-8">
        {/* Contact Section */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Support & Help</h1>
          <p className="text-gray-600 dark:text-gray-300 mb-8">
            Need help with The Dailies? We're here to assist you.
          </p>

          <div className="grid md:grid-cols-2 gap-6">
            <a
              href={`mailto:${contactEmail}`}
              className="flex items-start gap-4 p-6 bg-gray-50 dark:bg-gray-700 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
            >
              <div className="w-12 h-12 bg-primary-100 dark:bg-primary-900 rounded-xl flex items-center justify-center flex-shrink-0">
                <Mail className="w-6 h-6 text-primary-600 dark:text-primary-400" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-1">Email Support</h3>
                <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">
                  Get help with any issue
                </p>
                <p className="text-sm text-primary-600 dark:text-primary-400">{contactEmail}</p>
              </div>
            </a>

            <div className="flex items-start gap-4 p-6 bg-gray-50 dark:bg-gray-700 rounded-xl">
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-xl flex items-center justify-center flex-shrink-0">
                <MessageSquare className="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-1">In-App Feedback</h3>
                <p className="text-sm text-gray-600 dark:text-gray-300">
                  Send feedback directly from the app via Settings → Send Feedback
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Common Topics */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">Common Topics</h2>

          <div className="grid md:grid-cols-3 gap-4">
            <a
              href={`mailto:${contactEmail}?subject=Subscription Issue`}
              className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-700 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
            >
              <CreditCard className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              <span className="text-gray-700 dark:text-gray-200">Subscription Issues</span>
            </a>

            <a
              href={`mailto:${contactEmail}?subject=Bug Report`}
              className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-700 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
            >
              <Bug className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              <span className="text-gray-700 dark:text-gray-200">Report a Bug</span>
            </a>

            <a
              href={`mailto:${contactEmail}?subject=General Question`}
              className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-700 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
            >
              <HelpCircle className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              <span className="text-gray-700 dark:text-gray-200">General Questions</span>
            </a>

            <a
              href={`mailto:${contactEmail}?subject=Account Deletion Request`}
              className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-700 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
            >
              <Smartphone className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              <span className="text-gray-700 dark:text-gray-200">Delete My Account</span>
            </a>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">Frequently Asked Questions</h2>

          <div className="space-y-6">
            {faqs.map((faq, index) => (
              <div key={index} className="border-b border-gray-200 dark:border-gray-700 pb-6 last:border-0 last:pb-0">
                <h3 className="font-medium text-gray-900 dark:text-white mb-2">{faq.question}</h3>
                <p className="text-gray-600 dark:text-gray-300 text-sm">{faq.answer}</p>
              </div>
            ))}
          </div>
        </div>

        {/* App Info */}
        <div className="mt-8 text-center text-sm text-gray-500 dark:text-gray-400">
          <p className="mb-2">The Dailies - Daily Puzzle Games</p>
          <p>Developed by DBK Games</p>
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-4xl mx-auto px-4 py-8 text-center text-sm text-gray-500 dark:text-gray-400">
        <p>&copy; {new Date().getFullYear()} DBK Games. All rights reserved.</p>
        <div className="mt-2 space-x-4">
          <Link to="/privacy" className="hover:text-primary-600">Privacy Policy</Link>
          <Link to="/terms" className="hover:text-primary-600">Terms of Service</Link>
        </div>
      </footer>
    </div>
  )
}
