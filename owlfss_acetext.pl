% This file is part of the OWL verbalizer.
% Copyright 2008-2009, Kaarel Kaljurand <kaljurand@gmail.com>.
%
% The OWL verbalizer is free software: you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%
% The OWL verbalizer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License along with the
% OWL verbalizer. If not, see http://www.gnu.org/licenses/.

:- module(owlfss_acetext, [
		owlfss_acetext/2
	]).


/** <module> OWL 2 verbalizer

@author Kaarel Kaljurand
@version 2008-12-02

*/

:- use_module(table_1, [
		table_1/2
	]).

:- use_module(rewrite_subclassof, [
		rewrite_subclassof/2
	]).

:- use_module(owlace_dcg, [
		from_owl_to_ace/2
	]).

:- use_module(lexicon, [
		set_default_ns/1,
		asserta_lexicon/1
	]).


%% owlfss_acetext(+Owl:term, -AxiomSentenceList:list) is det.
%
% @param Owl is an OWL ontology in OWL 2 Functional-Style Syntax (Prolog notation)
% @param AxiomSentenceList is a list of Axiom-SentenceList pairs
%
owlfss_acetext(Owl, AxiomSentenceList) :-
	Owl = 'Ontology'(_Name, NS, AxiomList),
	set_default_ns(NS),
	asserta_lexicon(AxiomList),
	axiomlist_sentencelist(AxiomList, AxiomSentenceList).


%% axiomlist_sentencelist(+AxiomList:list, -AxiomSentenceList:list) is det.
%
% @param AxiomList is a list of OWL axioms
% @param AxiomSentenceList is a list of Axiom-SentenceList pairs
%
axiomlist_sentencelist([], []).

axiomlist_sentencelist([Axiom | AxiomList], [Axiom-[] | SentenceList]) :-
	is_ignore(Axiom),
	!,
	axiomlist_sentencelist(AxiomList, SentenceList).

axiomlist_sentencelist([Axiom | AxiomList], [Axiom-SentenceList1 | SentenceList]) :-
	table_1(Axiom, EquivalentAxioms),
	!,
	axiomlist_sentencelist_x(EquivalentAxioms, SentenceList1),
	axiomlist_sentencelist(AxiomList, SentenceList).

axiomlist_sentencelist([UnsupportedAxiom | AxiomList], [UnsupportedAxiom-'BUG: axiom unsupported' | SentenceList]) :-
	axiomlist_sentencelist(AxiomList, SentenceList).


%% axiomlist_sentencelist_x(+AxiomList:list, -SentenceList:list) is det.
%
% @param AxiomList is a list of OWL axioms
% @param SentenceList is a list of ACE sentences
%
axiomlist_sentencelist_x([], []).

axiomlist_sentencelist_x([Axiom | AxiomList], [Sentence | SentenceList]) :-
	rewrite_subclassof(Axiom, RewrittenAxiom),
	from_owl_to_ace(RewrittenAxiom, Sentence),
	!,
	axiomlist_sentencelist_x(AxiomList, SentenceList).

axiomlist_sentencelist_x([UnsupportedAxiom | AxiomList], [ErrorMessage | SentenceList]) :-
	with_output_to(atom(ErrorMessage), format("/* BUG: axiom too complex: ~w */", [UnsupportedAxiom])),
	axiomlist_sentencelist_x(AxiomList, SentenceList).


%% is_ignore(+Axiom:term) is det.
%
% Certain non-logical axioms are ignored.
%
% Note that we experimentally ignored the SubClassOf-axioms
% where the super class is owl:Thing as this is the case without saying.
% However, this does not seem to be a good idea in the context of synchronizing in ACE View.
%
% @param Axiom is an OWL axiom
%
is_ignore('Declaration'(_)).
is_ignore('Prefix'(_, _)).

is_ignore('AnnotationAssertion'(_, _, _)).

% @deprecated
is_ignore('EntityAnnotation'(_, _)).

% @deprecated
is_ignore('Annotation'(_, _)).

is_ignore('Imports'(_)).

%is_ignore('SubClassOf'(_, 'Class'('owl:Thing'))).
