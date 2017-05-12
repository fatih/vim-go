import deoplete.util

from .base import Base

class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'go'
        self.mark = '[go]'
        self.filetypes = ['go']
        self.rank = 100
        self.min_pattern_length = 0
        self.is_bytepos = True

    def get_complete_position(self, context):
        return self.vim.call('go#complete#Complete', 1, 0)

    def gather_candidates(self, context, **kwargs):
        return self.vim.call('go#complete#Complete', 0, 0)
